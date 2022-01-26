#!groovy

import jenkins.model.Jenkins

Jenkins jenkins = Jenkins.getInstance()
jenkins.cli.get().setEnable(false)
jenkins.save()