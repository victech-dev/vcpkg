# Custom Vcpkg for victech

## ports_boost

boost build 오류 및 arm64-linux, arm-linux 지원을 위한 수정을 반영함

## tensorflow support

아래와 같은 조합의 tensorflow_cc 빌드를 지원함

* tensorflow 2.3.1
* cuda 11.0 (10.2 for Jetson)
* cuDNN 8.0

protobuf는 tensorflow 내부 버전과 맞추기 위해 특정 버전을 사용하도록 custom port 작성됨

## Usage

for arm64-linux

```
./vcpkg install opencv4[contrib,core,cuda,dnn,ffmpeg,jpeg,opengl,png,tiff,webp] boost protobuf libjpeg-turbo zlib glog tensorflow-cc darknet[opencv-cuda,cudnn] tkdnn freetype harfbuzz --triplet arm64-linux --overlay-ports=./victech/ports

```

for x64-linux

```
./vcpkg install opencv4[contrib,core,cuda,dnn,ffmpeg,jpeg,opengl,png,tiff,webp] boost protobuf libjpeg-turbo zlib realsense2 glog tensorflow-cc darknet[opencv-cuda,cudnn] tkdnn freetype harfbuzz --triplet x64-linux --overlay-ports=./victech/ports
```

for x64-windows

```
./vcpkg install opencv4[contrib,core,cuda,dnn,ffmpeg,jpeg,opengl,png,tiff,webp] boost protobuf libjpeg-turbo zlib realsense2 glog tensorflow-cc darknet[opencv-cuda,cudnn] freetype harfbuzz --triplet x64-windows --overlay-ports=./victech/ports
```

## Triplet 별 참고

### x64-linux

ubuntu 18.04 / WSL ubuntu 18.04 에서 테스트 되었음

### x64-windows

tkDNN은 windows를 지원하지 않는다.

#### cuda toolkit & cuDNN 설치

tensorflow는 vcpkg의 binary를 이용하지 않고, system의 binary를 직접 이용한다.

https://victech.atlassian.net/wiki/spaces/DCSOFT/pages/45613136/CUDA+Toolkit+cuDNN

