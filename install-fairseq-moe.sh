#!/bin/bash
# Installs in current Python environment.
# Set that up before running this

if [ -z $CONDA_PREFIX ];
then
    printf "Must be in an active conda environment\n"
    exit 1
fi

set -o errexit
set -o nounset
set -o pipefail

SRC_DIR=$(readlink -f .)

printf "Installing Python requirements"
pip install -r "${SRC_DIR}/requirements.txt"  -f https://download.pytorch.org/whl/torch_stable.html

printf "Installing Apex"
git clone https://github.com/NVIDIA/apex
pushd apex
# Avoid CUDA extension + Pytorch complaint.  This is okay on Azure VMs. 
sed -i "s/(bare_metal_version != torch_binary_version)/False/g" setup.py
python -m pip install -v --no-cache-dir --global-option="--cpp_ext" \
    --global-option="--cuda_ext" \
    --global-option="--deprecated_fused_adam" \
    --global-option="--xentropy" \
    --global-option="--fast_multihead_attn" .
popd

printf "Installing NCCL"
git clone https://github.com/NVIDIA/nccl.git
pushd nccl
make clean && make -j src.build
popd

printf "Installing Megatron fork"
git clone https://github.com/ngoyal2707/Megatron-LM.git
pushd Megatron-LM
git checkout fairseq_v2
pip install -e .
popd

printf "Installing fairseq (moe branch)"
git clone https://github.com/pytorch/fairseq
pushd fairseq
git checkout moe
pip install -e .
popd

