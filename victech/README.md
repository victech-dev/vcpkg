# Custom Vcpkg for victech

## ports_arm-linux

raspabian 빌드 지원을 위해서 수정한 ports들이 모여있음

for short, run `./vcpkg install <>:arm-linux --overlay-triplet=./victech/ports_arm-linux`

## tensorflow support

아래와 같은 조합의 tensorflow_cc 빌드를 지원함

* tensorflow 1.15.0
* cuda 10.0
* cuDNN 7.6.0
* nccl 2.3.7

### x64-windows

#### visual studio version issue

cuda 10.0이 visual studio 2019로 빌드가 되지 않아서 2017 community를 설치해야 한다.

빌드 시에도 강제로 2017을 이용하게 해야 하는데 이를 위해서 triplets_tensorflow/x64-windows.cmake 을 사용해야 한다.

#### protobuf version issue

tf 1.15는 vendored protobuf 3.8.0 을 사용하고 있고 protobuf:x64-windows의 버전과 맞지 않아 오류가 발생한다.

그래서 protobuf:x64-windows의 버전을 강제로 맞춰 주어야 한다.

#### Usage

`./vcpkg install protobuf:x64-windows tensorflow-cc:x64-windows --overlay-ports=./victech/ports_tensorflow --overlay-triplets=./victech/triplets_tensorflow`

### x64-linux

ubuntu 18.04 / WSL ubuntu 18.04 에서 테스트 되었음

#### cuda toolkit & cuDNN 설치

https://victech.atlassian.net/wiki/spaces/DCSOFT/pages/45613136/CUDA+Toolkit+cuDNN

#### nccl 설치

WSL 상에서 빌드 시 gpu 지원 빌드를 위해서는 nccl 설치가 추가로 필요하다. (runtime에서는 필요 없음)

https://docs.nvidia.com/deeplearning/sdk/nccl-install-guide/index.html
[Download NCCL v2.3.7, for CUDA 10.0, Nov 8 & Dec 14, 2018]

```
wget https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
sudo dpkg -i nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
sudo apt install libnccl2=2.3.7-1+cuda10.0 libnccl-dev=2.3.7-1+cuda10.0
```

#### Usage

`./vcpkg install protobuf:x64-linux tensorflow-cc:x64-linux --overlay-ports=./victech/ports_tensorflow`