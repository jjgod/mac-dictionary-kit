#ifndef _STARDICT_RESOURCE_STORAGE_H_
#define _STARDICT_RESOURCE_STORAGE_H_

#include <string>

class File_ResourceStorage {
public:
	File_ResourceStorage(const char *resdir);
	const char *get_file_path(const char *key);
	const char *get_file_content(const char *key);
private:
	std::string resdir;
	std::string filepath;
};

class Database_ResourceStorage {
public:
	Database_ResourceStorage();
	bool load(const char *rifofilename);
	const char *get_file_path(const char *key);
	const char *get_file_content(const char *key);
};

class ResourceStorage {
public:
	ResourceStorage();
	~ResourceStorage();
	bool load(const char *dirname);
	int is_file_or_db;
	const char *get_file_path(const char *key);
	const char *get_file_content(const char *key);
private:
	File_ResourceStorage *file_storage;
	Database_ResourceStorage *database_storage;
};

#endif
