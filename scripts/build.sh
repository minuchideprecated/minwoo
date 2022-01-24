#!/bin/bash
DEPLOY_DIR=/opt/minwoo.kim
sudo docker run -it --name jekyll-builder -v $(pwd):/srv/jekyll --rm jekyll/jekyll jekyll build && \
    sudo rm -rf $DEPLOY_DIR && \
    sudo cp -a $(pwd)/_site $DEPLOY_DIR
