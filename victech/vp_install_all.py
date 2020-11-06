import os
import sys
import platform
import shutil
import subprocess
from pathlib import Path

def get_identity_file():
    ssh_path = Path.home() / '.ssh'
    if (ssh_path / 'id_rsa').is_file():
        return str(ssh_path / 'id_rsa')
    for f in ssh_path.iterdir():
        if f.is_file() and f.read_text().startswith("-----BEGIN RSA PRIVATE KEY-----"):
            return str(f)
    return None

# check working directory
cwd = Path(os.getcwd())
assert cwd.stem == 'vcpkg', "Run this script in vcpkg folder"

# resolve triplet
triplet = None
cache_path = None
if sys.platform == 'linux':
    if platform.machine() == 'aarch64':
        triplet = "arm64-linux"
    else:
        triplet = "x64-linux"
    cache_path = Path.home() / '.cache' / 'vcpkg'
elif sys.platform.startswith('win'):
    triplet  = "x64-windows"
    cache_path = Path(os.getenv('LOCALAPPDATA')) / 'vcpkg'
assert triplet is not None
print("-- triplet:", triplet)

# define package list
pkg_list = [
    "opencv4[contrib,core,cuda,dnn,ffmpeg,jpeg,opengl,png,tiff,webp]",
    "boost",
    "protobuf",
    "libjpeg-turbo",
    "zlib",
    "glog",
    "tensorflow",
    "darknet[opencv-cuda,cudnn]",
    "tkdnn",
    "freetype",
    "harfbuzz",
]
print("-- package list:", pkg_list)

# remove previous install/package/cache directories
print("-- removing previous buildtrees")
shutil.rmtree(str(cwd/'buildtrees'), ignore_errors=True)
print("-- removing previous installed")
shutil.rmtree(str(cwd/'installed'), ignore_errors=True)
print("-- removing previous packages")
shutil.rmtree(str(cwd/'packages'), ignore_errors=True)
print("-- removing previous downloads")
shutil.rmtree(str(cwd/'downloads'), ignore_errors=True)
print("-- removing previous cache")
shutil.rmtree(str(cache_path), ignore_errors=True)

# run vcpkg install
install_cmds = ["./vcpkg", "install", *pkg_list, "--triplet", triplet, "--overlay-ports=victech/ports"]
print("-- run vcpkg install:", " ".join(install_cmds))
subprocess.run(install_cmds)

# export results
export_cmds = ["./vcpkg", "export", *pkg_list, "--triplet", triplet, "--zip", f"--output=vcpkg_{triplet}"]
print("-- run vcpkg export:", " ".join(export_cmds))
subprocess.run(export_cmds)

# upload to dc-base
upload_host = "dev@192.168.2.100"
upload_path = "/workspace/webroot/port_8082/download/vicpilot/vcpkg"
identity_file = get_identity_file()
upload_cmds = ["scp", "-i", identity_file, f"vcpkg_{triplet}.zip", f"{upload_host}:{upload_path}"]
print("-- uploading export file:", " ".join(upload_cmds))
subprocess.run(upload_cmds)

# erase output file
os.remove(f"vcpkg_{triplet}.zip")

