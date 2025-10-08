class_name SaveDataUpgrader
## Provides backwards compatibility with old save files.
##
## SaveDataUpgrader can update the 'version' tag, but any other version-specific updates must be defined externally.
## These version-specific updates can be incorporated via SaveDataUpgrader's 'add_upgrade_method' method.

## Externally defined methods which perform granular version-specific updates, capable of upgrading individual keys.
class UpgradeMethod:
	## Method that performs the upgrade
	var callable: Callable
	
	## Version that this method upgrades from
	var old_version: String
	
	## Version that this method upgrades to
	var new_version: String


## Externally defined methods which performs updates after all granular upgrade_methods are invoked.
class PostUpgradeMethod:
	## Method that performs the upgrade
	var callable: Callable
	
	## Version that this method upgrades from
	var old_version: String
	
	## Version that this method upgrades to
	var new_version: String


## Newest version which everything should upgrade to.
var current_version := ""

## Externally defined methods which perform granular version-specific updates, capable of upgrading individual
## keys.[br]
## [br]
## These methods should have the following signature:[br]
## [br]
## 	* func _upgrade_xyz(json_dict: Dictionary, old_key: String) -> void[br]
## [br]
## The upgrade method should modify the specified key in the dictionary.
var _upgrade_methods: Dictionary[String, UpgradeMethod] = {}

## Externally defined methods which performs updates after all granular upgrade methods are invoked.[br]
## [br]
## These methods should have the following signature:[br]
## [br]
## 	* func _post_upgrade_xyz(json_dict: Dictionary) -> void[br]
## [br]
## The upgrade method should modify the dictionary.
var _post_upgrade_methods: Dictionary[String, PostUpgradeMethod] = {}


## Adds a new externally defined method that performs granular version-specific updates, capable of upgrading
## individual keys.[br]
## [br]
## SaveDataUpgrader does not have logic for upgrading specific save data versions. This upgrade logic must be defined
## on an external object and incorporated via this 'add_upgrade_method' method.[br]
## [br]
## This method should have the following signature:[br]
## [br]
## 	* func _upgrade_xyz(json_dict: Dictionary, key: String) -> void[br]
## [br]
## The upgrade method should modify the specified key in the dictionary.
func add_upgrade_method(callable: Callable, old_version: String, new_version: String) -> void:
	var upgrade_method: UpgradeMethod = UpgradeMethod.new()
	upgrade_method.callable = callable
	upgrade_method.old_version = old_version
	upgrade_method.new_version = new_version
	_upgrade_methods[old_version] = upgrade_method


## Adds a new externally defined methods which performs updates after all granular upgrade methods are invoked.[br]
## [br]
## This method should have the following signature:[br]
## [br]
## 	* func _post_upgrade_xyz(json_dict: Dictionary) -> void[br]
## [br]
## The upgrade method should modify the dictionary.
func add_post_upgrade_method(callable: Callable, old_version: String, new_version: String) -> void:
	var post_upgrade_method: PostUpgradeMethod = PostUpgradeMethod.new()
	post_upgrade_method.callable = callable
	post_upgrade_method.old_version = old_version
	post_upgrade_method.new_version = new_version
	_post_upgrade_methods[old_version] = post_upgrade_method


## Returns [code]true[/code] if the specified json is an older version which we can upgrade.
func needs_upgrade(json_dict: Dictionary) -> bool:
	var result := false
	var version: String = json_dict.get("version", "")
	if version == current_version:
		result = false
	elif _upgrade_methods.has(version) or _post_upgrade_methods.has(version):
		result = true
	else:
		push_warning("Unrecognized save data version: '%s'" % [version])
	return result


## Transforms the specified json dictionary to the newest format.
func upgrade(json_dict: Dictionary[String, Variant]) -> void:
	while needs_upgrade(json_dict):
		var old_version: String = json_dict.get("version")
		
		if not _upgrade_methods.has(old_version) and not _post_upgrade_methods.has(old_version):
			# couldn't upgrade; most likely a newer version
			push_warning("Unrecognized save data version: '%s'" % [old_version])
			break
		
		_perform_upgrade_step(json_dict)
		
		if json_dict.get("version") == old_version:
			# upgrade increment failed, but the data might still load
			push_warning("Couldn't upgrade save data version '%s'" % [old_version])
			break


## Performs one incremental step in the upgrade.[br]
## [br]
## Performs per-key upgrades via the UpgradeMethod, then a full pass via PostUpgradeMethod.
func _perform_upgrade_step(json_dict: Dictionary[String, Variant]) -> void:
	var old_version: String = json_dict.get("version")
	
	var new_version: String
	if _upgrade_methods.has(old_version):
		new_version = _upgrade_methods.get(old_version).new_version
	elif _post_upgrade_methods.has(old_version):
		new_version = _post_upgrade_methods.get(old_version).new_version
	
	var upgrade_method: UpgradeMethod = _upgrade_methods.get(old_version)
	var old_keys: Array[String] = json_dict.keys()
	for old_key: String in old_keys:
		match old_key:
			"version":
				json_dict["version"] = new_version
			_:
				if upgrade_method:
					upgrade_method.callable.call(json_dict, old_key)
	
	var post_upgrade_method: PostUpgradeMethod = _post_upgrade_methods.get(old_version)
	if post_upgrade_method:
		post_upgrade_method.callable.call(json_dict)
