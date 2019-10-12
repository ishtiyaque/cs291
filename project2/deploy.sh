#!/bin/bash

gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://us.gcr.io
docker push us.gcr.io/cs291-f19/project2_${CS291_ACCOUNT}
gcloud beta run deploy \
  --allow-unauthenticated \
  --concurrency 80 \
  --image us.gcr.io/cs291-f19/project2_${CS291_ACCOUNT} \
  --memory 128Mi \
  --platform managed \
  --project cs291-f19 \
  --region us-central1 \
  --service-account project2@cs291-f19.iam.gserviceaccount.com \
  --set-env-vars RACK_ENV=production \
  ${CS291_ACCOUNT}

