def FlagsForFile(filename, **kwargs):
    return {
        'flags': ['-x', 'c++', '-std=c++11', '-Wall', '-Wextra', '-Werror',
                  '-pedantic'],
    }
