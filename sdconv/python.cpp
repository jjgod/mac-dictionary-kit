// python.cpp

#include <libgen.h>
#include <python2.7/Python.h>
#include "python.h"

PyObject *py_transform_func;

static char *copy_module_name_from_file(const char *file)
{
    char *module = strdup(basename((char *) file));
    if (! module)
        return NULL;

    int len = strlen(module);
    int i;

    for (i = len - 1; i >= 0; i--)
        if (module[i] == '.')
            module[i] = '\0';

    return module;
}

void add_directory_of_file_to_path(const char *file)
{
    PyRun_SimpleString("import sys");

    char buf[256];
    snprintf(buf, sizeof(buf), "sys.path.insert(0, '%s')",
             dirname((char *) file));

    PyRun_SimpleString(buf);
}

bool init_python(const char *file)
{
    PyObject *module;

    char *module_name = copy_module_name_from_file(file);
    if (! module_name)
        goto failed2;

    Py_Initialize();
    add_directory_of_file_to_path(file);

    fprintf(stderr, "loading module %s...\n", module_name);
    module = PyImport_ImportModule(module_name);
    if (! module)
        goto failed1;

    fprintf(stderr, "locating function transform...\n");
    /* locate py_module.transform() */
    py_transform_func = PyObject_GetAttrString(module,
                                               "transform");
    Py_DECREF(module);
    if (! py_transform_func)
        goto failed1;

    return true;

failed1:
    free(module_name);

failed2:
    return false;
}

void fini_python()
{
    Py_DECREF(py_transform_func);
    Py_Finalize();
}

bool convert_with_python(gchar *src, GString *dest)
{
    PyObject *pargs = Py_BuildValue("(s)", src);
    PyObject *pstr  = PyEval_CallObject(py_transform_func, pargs);

    if (pstr)
    {
        char *cstr = NULL;
        PyArg_Parse(pstr, "s", &cstr);

        if (cstr)
            g_string_append(dest, cstr);

        Py_DECREF(pstr);
    } else
        g_string_append(dest, "failed to transform\n");

    Py_DECREF(pargs);

    return true;
}

