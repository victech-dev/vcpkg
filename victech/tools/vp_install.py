import os
import sys
import platform
import shutil
import subprocess
from pathlib import Path
import argparse

parser = argparse.ArgumentParser(description="vp_install parser")
parser.add_argument('--exportonly', dest='exportonly', action='store_true')
parser.set_defaults(exportonly=False)
parser.add_argument('--clean', dest='clean', action='store_true')
parser.set_defaults(clean=False)
args = parser.parse_args()

def get_identity_file():
    ssh_path = Path.home() / '.ssh'
    if (ssh_path / 'id_rsa').is_file():
        return str(ssh_path / 'id_rsa')
    if ssh_path.is_dir():
        for f in ssh_path.iterdir():
            if f.is_file() and f.read_text().startswith("-----BEGIN RSA PRIVATE KEY-----"):
                return str(f)
    return None

# check working directory
cwd = Path(os.getcwd())
assert cwd.stem.startswith('vcpkg'), "Run this script in vcpkg folder"

# resolve triplet
triplet = None
cache_path = None
vcpkg_envs = {}
if sys.platform == 'linux':
    if platform.machine() == 'aarch64':
        triplet = "arm64-linux"
        vcpkg_envs['VCPKG_FORCE_SYSTEM_BINARIES'] = '1'
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
    "minizip",
    "curl",
    "upb",
    "grpc"
]
if not triplet.endswith('-windows'):
    pkg_list = pkg_list + ["protobuf-c[tools]"]
print("-- package list:", pkg_list)

if not args.exportonly and args.clean:
    # remove previous install/package/cache directories
    print("-- removing previous buildtrees")
    shutil.rmtree(str(cwd/'buildtrees'), ignore_errors=True)
    print("-- removing previous installed")
    shutil.rmtree(str(cwd/'installed'), ignore_errors=True)
    print("-- removing previous packages")
    shutil.rmtree(str(cwd/'packages'), ignore_errors=True)
    # print("-- removing previous downloads")
    # shutil.rmtree(str(cwd/'downloads'), ignore_errors=True)
    print("-- removing previous cache")
    shutil.rmtree(str(cache_path), ignore_errors=True)

if not args.exportonly:
    # run vcpkg install
    install_cmds = ["./vcpkg", "install", *pkg_list, "--triplet", triplet, "--overlay-ports=victech/ports"]
    print("-- run vcpkg install:", " ".join(install_cmds))
    subprocess.run(install_cmds, env={**os.environ, **vcpkg_envs})

# export results
export_cmds = ["./vcpkg", "export", *pkg_list, "--triplet", triplet, "--raw", f"--output=vcpkg_{triplet}"]
print("-- run vcpkg export:", " ".join(export_cmds))
subprocess.run(export_cmds, env={**os.environ, **vcpkg_envs})

# create tar.gz
tar_cmds = ["tar", "-czf", f"vcpkg_{triplet}.tar.gz", f"./vcpkg_{triplet}"]
print("-- compressing to tar.gz:", " ".join(tar_cmds))
subprocess.run(tar_cmds)

# upload to dc-base
upload_host = "dev@192.168.2.100"
upload_path = "/workspace/webroot/port_8082/download/vicpilot/vcpkg"
identity_file = get_identity_file()
if identity_file is not None:
    upload_cmds = ["scp", "-i", identity_file, f"vcpkg_{triplet}.tar.gz", f"{upload_host}:{upload_path}"]
else:
    upload_cmds = ["scp", f"vcpkg_{triplet}.tar.gz", f"{upload_host}:{upload_path}"]
print("-- uploading export file:", " ".join(upload_cmds))
subprocess.run(upload_cmds)

# erase output file
os.remove(f"vcpkg_{triplet}.tar.gz")
shutil.rmtree(f"vcpkg_{triplet}", ignore_errors=True)
print("-- done")

