# Custom Vcpkg for victech



## tensorflow support

아래와 같은 조합의 tensorflow C API 빌드를 지원함 

* tensorflow 2.3.1
* cuda 11.0 (10.2 for Jetson)
* cuDNN 8.0

protobuf는 tensorflow 내부 버전과 맞추기 위해 특정 버전을 사용하도록 custom port 작성됨

## Usage

for arm64-linux

```
VCPKG_FORCE_SYSTEM_BINARIES=1 ./vcpkg install opencv4[contrib,core,cuda,dnn,ffmpeg,jpeg,opengl,png,tiff,webp] boost protobuf libjpeg-turbo zlib glog tensorflow darknet[opencv-cuda,cudnn] tkdnn freetype harfbuzz minizip curl --triplet arm64-linux --overlay-ports=victech/ports
```

for x64-linux

```
./vcpkg install opencv4[contrib,core,cuda,dnn,ffmpeg,jpeg,opengl,png,tiff,webp] boost protobuf libjpeg-turbo zlib glog tensorflow darknet[opencv-cuda,cudnn] tkdnn freetype harfbuzz minizip curl --triplet x64-linux --overlay-ports=./victech/ports
```

for x64-windows

```
./vcpkg install opencv4[contrib,core,cuda,dnn,ffmpeg,jpeg,opengl,png,tiff,webp] boost protobuf libjpeg-turbo zlib glog tensorflow darknet[opencv-cuda,cudnn] tkdnn freetype harfbuzz minizip curl --triplet x64-windows --overlay-ports=./victech/ports
```

모든 triplet 에 대해서, 아래 스크립트는 install, export, dc-base uploading 까지 처리해줌

```
python victech/tools/vp_install.py
```



## Triplet 별 참고

### x64-linux

ubuntu 18.04 / WSL ubuntu 18.04 에서 테스트 되었음

#### CUDA Toolkit & CuDNN & TensorRT 설치

tensorflow는 vcpkg의 binary를 이용하지 않고, system의 binary를 직접 이용한다.

https://victech.atlassian.net/wiki/spaces/DCSOFT/pages/45613136/CUDA+Toolkit+cuDNN

