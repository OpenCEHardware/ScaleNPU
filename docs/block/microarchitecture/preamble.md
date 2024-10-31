# Microarchitecture preamble

The following sections focus on explaning the inner workings of each of the modules of the NPU. If this is your first time reading the document we recommend you to follow the order in which each of the modules is presented, as this is the orden in which they were implemnted and knolegne of the previous block will be helpful to understand the current one. 


## General idea and basics

This aditional section helps clarify basic knowledge to undertand the desing. If you are already familiar with NPUs you can skip this part.

The general idea of the NPU as said earlier is to be able to accelerate the infenrece of a pretrained neural networks. This basically means we want to be able to do matrix multiplication as quickly and effiecient as posible. AS you might know matrix multiplication consists solely on multiplication and sums of the values of the multplied matrices. In hardware the matrix multiplication is achived via a square systolic array of interconnected MACs. Addtionally in machine learning this multiplication is then accululated with a bias value and passed to a activation function. All of these operations are the main objective of the computational part of the NPU. Additionally as this NPU is limited in memory and data types a additional quantization operation is added into the mix. In this case we are doing symmetric power of 2 quantization, which simply means discating bits (via a left shift). 

The rest of the NPU is dedicated to storage and control. With storage we speak of input, weight, and bias values. This means both how they are retrieved from memory and stored within the NPU during computation. And of course how the results are sent back to memory.
With control we refer of both how this values are handled inside of the NPU and how the communitations and instructions coming from CPU happen. 

In a way the NPU can be viewed 