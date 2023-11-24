import sys

# This python script install/uninstall dropbox key from example project.
#
# Register a Dropbox API app from https://www.dropbox.com/developers .
# Fill dropbox key and dropbox secret below.
#
# Do NOT commit/push your key/secret to GIT.
APP_KEY = ''
APP_SECRET = ''

def replace_string_in_file(file_path, old_str, new_str):
    try:
        with open(file_path, 'r') as file:
            file_content = file.read()

        modified_content = file_content.replace(old_str, new_str)

        with open(file_path, 'w') as file:
            file.write(modified_content)
    except FileNotFoundError:
        print(f'Error: The file "{file_path}" was not found.')
    except Exception as e:
        print(f'An error occurred: {str(e)}')


def install():
    print('install dropbox key/secret...')
    replace_string_in_file('lib/main.dart', "'dropbox_key';", f"'{APP_KEY}';")
    replace_string_in_file('lib/main.dart', "'dropbox_secret';", f"'{APP_SECRET}';")
    replace_string_in_file('ios/Runner/Info.plist', 'dropbox_key', APP_KEY)
    replace_string_in_file('android/app/src/main/AndroidManifest.xml', 'dropbox_key', APP_KEY)

def uninstall():
    print('UNinstall dropbox key/secret...')
    replace_string_in_file('lib/main.dart', f"'{APP_KEY}';", "'dropbox_key';")
    replace_string_in_file('lib/main.dart', f"'{APP_SECRET}';", "'dropbox_secret';")
    replace_string_in_file('ios/Runner/Info.plist', APP_KEY, 'dropbox_key')
    replace_string_in_file('android/app/src/main/AndroidManifest.xml', APP_KEY, 'dropbox_key')

def print_usage():
    print("Usage:")
    print("  -i : Install")
    print("  -u : Uninstall")

def main():
    if len(APP_KEY) == 0 or len(APP_SECRET) == 0:
        print("Fill APP_KEY and APP_SECRET with your dropbox developer account by editing dropbox_key.py")
        sys.exit(1)

    if len(sys.argv) != 2:
        print_usage()
        sys.exit(1)


    option = sys.argv[1]

    if option == "-i":
        install()
    elif option == "-u":
        uninstall()
    else:
        print_usage()
        sys.exit(1)

if __name__ == "__main__":
    main()

