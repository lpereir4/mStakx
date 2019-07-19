#! /usr/bin/env bash

gcloud compute forwarding-rules delete entry-point --quiet --global
gcloud compute target-http-proxies delete mstakx-lb-target-proxy --quiet
gcloud compute url-maps delete mstakx-lb --quiet
gcloud compute backend-services delete mstakx-backend-service --quiet --global
gcloud compute health-checks delete tcp mstakx-healthcheck --quiet

gcloud compute health-checks create tcp mstakx-healthcheck\
  --check-interval=5\
  --healthy-threshold=2\
  --port=32727\
  --port-name=http\
  --timeout=4\
  --unhealthy-threshold=2

gcloud compute backend-services create mstakx-backend-service\
 --connection-draining-timeout=300\
 --health-checks=mstakx-healthcheck\
 --load-balancing-scheme=EXTERNAL\
 --protocol=http\
 --port-name=http\
 --timeout=4s \
 --global

gcloud compute backend-services add-backend mstakx-backend-service\
 --instance-group=mstakx-instance-group\
 --max-utilization=0.8\
 --balancing-mode=UTILIZATION\
 --global\
 --instance-group-zone=europe-west2-a

gcloud compute url-maps create mstakx-lb --default-service=mstakx-backend-service

gcloud compute target-http-proxies create mstakx-lb-target-proxy --url-map=mstakx-lb

gcloud compute addresses create entry-point --global --network-tier=PREMIUM --ip-version IPV4

IP_ADDRESS=$(gcloud compute addresses describe entry-point --global | grep address: | awk -F ': ' '{ print $2 }')

gcloud compute forwarding-rules create entry-point\
 --target-http-proxy=mstakx-lb-target-proxy\
 --load-balancing-scheme=EXTERNAL\
 --ip-protocol TCP\
 --ports=80\
 --global\
 --address ${IP_ADDRESS}

