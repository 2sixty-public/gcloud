FROM google/cloud-sdk:234.0.0-alpine
RUN apk add --update nodejs=8.14.0-r0 npm=8.14.0-r0
RUN npm install -g @angular/cli