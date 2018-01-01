!#/bin/bash
set -e
gcloud compute instances create "reddit-full" \
--zone "europe-west1-b" \
--machine-type "g1-small" \
--subnet "default" \
--tags "puma-server" \ 
--image "reddit-full-1514326289" \
--image-project "lucky-almanac-188814" \
--boot-disk-size "10" \
--boot-disk-type "pd-standard" \
--boot-disk-device-name "reddit-full" \
--restart-on-failure