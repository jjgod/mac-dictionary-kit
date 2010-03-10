#include "storage.h"
#include <glib.h>

ResourceStorage::ResourceStorage()
{
	file_storage = NULL;
	database_storage = NULL;
}

ResourceStorage::~ResourceStorage()
{
	delete file_storage;
	delete database_storage;
}

bool ResourceStorage::load(const char *dirname)
{
	std::string resdir(dirname);
	resdir += G_DIR_SEPARATOR_S "res";
	if (g_file_test(resdir.c_str(), G_FILE_TEST_IS_DIR)) {
		file_storage = new File_ResourceStorage(resdir.c_str());
		is_file_or_db = 1;
		return false;
	}
	std::string rifofilename(dirname);
	rifofilename += G_DIR_SEPARATOR_S "res.rifo";
	if (g_file_test(rifofilename.c_str(), G_FILE_TEST_EXISTS)) {
		database_storage = new Database_ResourceStorage();
		bool failed = database_storage->load(rifofilename.c_str());
		if (failed) {
			delete database_storage;
			database_storage = NULL;
			return true;
		}
		is_file_or_db = 0;
		return false;
	}
	return true;
}

const char *ResourceStorage::get_file_path(const char *key)
{
	if (is_file_or_db)
		return file_storage->get_file_path(key);
	else
		return database_storage->get_file_path(key);
}

const char *ResourceStorage::get_file_content(const char *key)
{
	if (is_file_or_db)
		return file_storage->get_file_content(key);
	else
		return database_storage->get_file_content(key);
}

File_ResourceStorage::File_ResourceStorage(const char *resdir_)
{
	resdir = resdir_;
}

const char *File_ResourceStorage::get_file_path(const char *key)
{
	filepath = resdir;
	filepath += G_DIR_SEPARATOR;
	filepath += key;
	return filepath.c_str();
}

const char *File_ResourceStorage::get_file_content(const char *key)
{
	return NULL;
}

Database_ResourceStorage::Database_ResourceStorage()
{
}

bool Database_ResourceStorage::load(const char *rifofilename)
{
	return false;
}

const char *Database_ResourceStorage::get_file_path(const char *key)
{
	return NULL;
}

const char *Database_ResourceStorage::get_file_content(const char *key)
{
	return NULL;
}
