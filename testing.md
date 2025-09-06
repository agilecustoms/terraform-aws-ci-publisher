```shell
# login
aws sso login
export AWS_PROFILE=ac-dist-publisher-dev
aws sts get-caller-identity

# list bucket => success
aws s3 ls s3://agilecustoms-dist

# put object w/o tag, w/o suffix => failure
aws s3 cp testing.md s3://agilecustoms-dist/

# put object w/o tag, w/ suffix => failure
aws s3 cp testing.md s3://agilecustoms-dist/A/feature/testing.md

# put object w/ tag, w/o suffix => failure
aws s3api put-object --bucket agilecustoms-dist --key testing.md --body testing.md --tagging "Release=false"

# put object w/ tag, w/ bad suffix => failure
aws s3api put-object --bucket agilecustoms-dist --key feature/testing.md --body testing.md --tagging "Release=false"

# put object w/ tag, w/ suffix => success
aws s3api put-object --bucket agilecustoms-dist --key A/feature/testing.md --body testing.md --tagging "Release=false"

# override object w/ tag, w/ suffix => success
aws s3api put-object --bucket agilecustoms-dist --key A/feature/testing.md --body testing.md --tagging "Release=false"

# manually remove tag Release
# set tag Release=false => success
aws s3api put-object-tagging --bucket agilecustoms-dist --key A/feature/testing.md --tagging 'TagSet=[{Key=Release,Value=false}]'

# manually set tag Release=true
# override tag Release=false -> Release=true => failure
aws s3api put-object-tagging --bucket agilecustoms-dist --key A/feature/testing.md --tagging 'TagSet=[{Key=Release,Value=false}]'

# override object Release=true (no tags) = failure
aws s3api put-object --bucket agilecustoms-dist --key A/feature/testing.md --body testing.md

# override object Release=true -> Release=false => success - unfortunate, but unavoidable
aws s3api put-object --bucket agilecustoms-dist --key A/feature/testing.md --body testing.md --tagging "Release=false"
```
