# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

*** Settings ***
Resource            ../commonlib.robot
Resource            ../commonlib.robot

*** Variables ***
${OZONE_S3_HEADER_VERSION}     v4
${OZONE_S3_SET_CREDENTIALS}    true
${BUCKET}                      bucket-999

*** Keywords ***
Execute AWSS3APICli
    [Arguments]       ${command}
    ${output} =       Execute                    aws s3api --endpoint-url ${ENDPOINT_URL} ${command}
    [return]          ${output}

Execute AWSS3APICli and checkrc
    [Arguments]       ${command}                 ${expected_error_code}
    ${output} =       Execute and checkrc        aws s3api --endpoint-url ${ENDPOINT_URL} ${command}  ${expected_error_code}
    [return]          ${output}

Execute AWSS3Cli
    [Arguments]       ${command}
    ${output} =       Execute                     aws s3 --endpoint-url ${ENDPOINT_URL} ${command}
    [return]          ${output}

Install aws cli s3 centos
    Execute            sudo -E yum install -y awscli

Install aws cli s3 debian
    Execute            sudo -E apt-get install -y awscli

Setup v2 headers
                        Set Environment Variable   AWS_ACCESS_KEY_ID       ANYID
                        Set Environment Variable   AWS_SECRET_ACCESS_KEY   ANYKEY

Setup v4 headers
    Run Keyword if      '${SECURITY_ENABLED}' == 'true'     Kinit test user    testuser    testuser.keytab
    Run Keyword if      '${SECURITY_ENABLED}' == 'true'     Setup secure v4 headers
    Run Keyword if      '${SECURITY_ENABLED}' == 'false'    Setup dummy credentials for S3

Setup secure v4 headers
    ${result} =         Execute                    ozone s3 getsecret
    ${accessKey} =      Get Regexp Matches         ${result}     (?<=awsAccessKey=).*
    ${accessKey} =      Get Variable Value         ${accessKey}  sdsdasaasdasd
    ${secret} =         Get Regexp Matches         ${result}     (?<=awsSecret=).*
    ${accessKey} =      Set Variable               ${accessKey[0]}
    ${secret} =         Set Variable               ${secret[0]}
                        Execute                    aws configure set default.s3.signature_version s3v4
                        Execute                    aws configure set aws_access_key_id ${accessKey}
                        Execute                    aws configure set aws_secret_access_key ${secret}
                        Execute                    aws configure set region us-west-1

Setup dummy credentials for S3
                        Execute                    aws configure set default.s3.signature_version s3v4
                        Execute                    aws configure set aws_access_key_id dlfknslnfslf
                        Execute                    aws configure set aws_secret_access_key dlfknslnfslf
                        Execute                    aws configure set region us-west-1

Create bucket
    ${postfix} =         Generate Random String  5  [NUMBERS]
    Set Suite Variable   ${BUCKET}                  bucket-${postfix}
                         Create bucket with name    ${BUCKET}

Create bucket with name
    [Arguments]          ${bucket}
    ${result} =          Execute AWSS3APICli  create-bucket --bucket ${bucket}
                         Should contain              ${result}         Location
                         Should contain              ${result}         ${ENDPOINT_URL}/${bucket}

Setup s3 tests
    Run Keyword        Install aws cli
    Run Keyword if    '${OZONE_S3_SET_CREDENTIALS}' == 'true'    Setup v4 headers
    ${result} =        Execute And Ignore Error                  ozone sh volume create o3://${OM_SERVICE_ID}/s3v
                       Should not contain                        ${result}          Failed
    Run Keyword if    '${BUCKET}' == 'generated'                 Create bucket
