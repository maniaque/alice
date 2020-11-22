#!/bin/bash

terraform $1 -state=$2.tfstate ./terraform/$2