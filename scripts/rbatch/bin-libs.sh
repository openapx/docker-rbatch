#!/bin/bash


# -- install any updates 
apt-get update -y

# -- install any binary library dependenceis
apt-get install $(grep "^[^#;]" /opt/openapx/config/rbatch/libs | tr '\n' ' ') -y --no-install-recommends


