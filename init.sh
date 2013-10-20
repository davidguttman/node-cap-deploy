#!/bin/bash

mkdir -p config
curl https://raw.github.com/davidguttman/node-cap-deploy/master/deploy.rb > config/deploy.rb
curl https://raw.github.com/davidguttman/node-cap-deploy/master/opts.rb > config/opts.rb
$EDITOR config/opts.rb