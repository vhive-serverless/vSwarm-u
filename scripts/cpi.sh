#!/bin/bash

inst=$(awk '/system.detailed_cpu1.exec_context.thread_0.numInsts/ {print $2}' $1)
cycles=$(awk '/system.detailed_cpu1.numCycles/ {print $2}' $1)

echo $inst | awk '{printf"Insts:\t%i\n", $1}'
echo $cycles | awk '{printf"Cycles:\t%i\n", $1}'

# Also do the math:
echo $cycles $inst | awk '{ tmp=$1/$2 ; printf"CPI:\t%0.4f\n", tmp }'
echo $inst $cycles | awk '{ tmp=$1/$2 ; printf"IPC:\t%0.4f\n", tmp }'

