# Custom Vcpkg for victech

## ports_boost

boost build 오류 및 arm64-linux, arm-linux 지원을 위한 수정을 반영함

## tensorflow support

아래와 같은 조합의 tensorflow_cc 빌드를 지원함

* tensorflow 2.2.0
* cuda 10.1
* cuDNN 7
* nccl 2.7

protobuf는 tensorflow 내부 버전과 맞추기 위해 특정 버전을 사용하도록 custom port 작성됨

## Usage

for (x64|arm64)-linux

```
./vcpkg install opencv4[contrib,core,dnn,jpeg,opengl,png,tiff,webp] boost protobuf libjpeg-turbo zlib realsense2 glog tensorflow-cc darknet[opencv-cuda,cudnn] tkdnn --triplet arm64-linux --overlay-ports=./victech/ports_boost/ --overlay-ports=./victech/ports_tensorflow/
```

for x64-windows

```
./vcpkg install opencv4[contrib,core,dnn,jpeg,opengl,png,tiff,webp] boost protobuf libjpeg-turbo zlib realsense2 glog tensorflow-cc darknet[opencv-cuda,cudnn] --triplet x64-windows --overlay-ports=./victech/ports_boost/ --overlay-ports=./victech/ports_tensorflow/
```

## Triplet 별 참고

### x64-linux

ubuntu 18.04 / WSL ubuntu 18.04 에서 테스트 되었음

### x64-windows

tkDNN은 windows를 지원하지 않는다.

#### cuda toolkit & cuDNN 설치

tensorflow는 vcpkg의 binary를 이용하지 않고, system의 binary를 직접 이용한다.

https://victech.atlassian.net/wiki/spaces/DCSOFT/pages/45613136/CUDA+Toolkit+cuDNN

#### nccl 설치

WSL 상에서 빌드 시 gpu 지원 빌드를 위해서는 nccl 설치가 추가로 필요하다. (runtime에서는 필요 없음)

https://docs.nvidia.com/deeplearning/sdk/nccl-install-guide/index.html

[Download NCCL v2.7.6, for CUDA 10.1]

```
wget https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
sudo dpkg -i nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
sudo apt install libnccl2=2.7.6-1+cuda10.1 libnccl-dev=2.7.6-1+cuda10.1
```
