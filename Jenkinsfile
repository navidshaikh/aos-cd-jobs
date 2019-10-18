#!/usr/bin/env groovy

node {
    checkout scm
    def buildlib = load("pipeline-scripts/buildlib.groovy")
    def commonlib = buildlib.commonlib

    // Expose properties for a parameterized build
    properties(
        [
            buildDiscarder(
                logRotator(
                    artifactDaysToKeepStr: '',
                    artifactNumToKeepStr: '',
                    daysToKeepStr: '',
                    numToKeepStr: '')),
            [
                $class: 'ParametersDefinitionProperty',
                parameterDefinitions: [
                    [
                        name: 'STREAM',
                        description: 'Build stream to sync client from',
                        $class: 'hudson.model.ChoiceParameterDefinition',
                        choices: [
                            "4-stable",
                            "4.1.0-0.nightly",
                            "4.2.0-0.nightly",
                        ].join("\n"),
                        defaultValue: "4-stable"
                    ],
                    [
                        name: 'OC_MIRROR_DIR',
                        description: 'artifacts path under https://mirror.openshift.com',
                        $class: 'hudson.model.ChoiceParameterDefinition',
                        choices: [
                            "ocp",
                            "ocp-dev-preview",
                        ].join("\n"),
                        defaultValue: "ocp"
                    ],
                    [
                        name: 'MAIL_LIST_FAILURE',
                        description: 'Failure Mailing List',
                        $class: 'hudson.model.StringParameterDefinition',
                        defaultValue: [
                            'aos-art-automation+failed-oc-sync@redhat.com'
                        ].join(',')
                    ],
                    commonlib.suppressEmailParam(),
                    commonlib.mockParam(),
                ]
            ],
            disableConcurrentBuilds()
        ]
    )

    commonlib.checkMock()



    try {
        sshagent(['aos-cd-test']) {
            stage("sync ocp clients") {
		// must be able to access remote registry to extract image contents
		buildlib.registry_quay_dev_login()
                sh "./publish-clients-from-payload.sh ${env.WORKSPACE} ${STREAM} ${OC_MIRROR_DIR}"
            }
        }
    } catch (err) {
        def buildURL = env.BUILD_URL.replace('https://buildvm.openshift.eng.bos.redhat.com:8443', 'https://localhost:8888')
        commonlib.email(
            to: "${params.MAIL_LIST_FAILURE}",
            from: "aos-art-automation@redhat.com",
            replyTo: "aos-team-art@redhat.com",
            subject: "Error syncing ocp client from payload",
            body: """Encountered an error while syncing ocp client from payload: ${err}

Jenkins Job: ${buildURL}

""");
        currentBuild.description = "Error while syncing ocp client from payload:\n${err}"
        currentBuild.result = "FAILURE"
        throw err
    }
    buildlib.cleanWorkdir("${env.WORKSPACE}")
}
