c = get_config()


# Our user list
c.Authenticator.whitelist = [
########################################################
############## Modify the content BELOW ################
   'instructor1',
   'instructor2',
   'student1'
## Add the username of instructors and students above ##
########################################################
]


# instructor1 and instructor2 have access to a shared server:
c.JupyterHub.load_groups = {
########################################################
############## Modify the content BELOW ################
   'formgrader-course101': [ # This part has to change to "formgrader-STBIO440"
       'instructor1',
       'instructor2'
    ]
## Add the group list of instructors in this course. ##
#######################################################
]


# Start the notebook server as a service. The port can be whatever you want
# and the group has to match the name of the group defined above. The name of
# the service MUST match the name of your course.
c.JupyterHub.services = [
##############################
## Modify the content BELOW ##
    {
        'name': 'course101', # This part has to change to "STBIO440"
        'url': 'http://127.0.0.1:9999',
        'command': [
            'jupyterhub-singleuser',
            '--group=formgrader-course101', # This part has to change to "formgrader-STBIO440"
            '--debug',
        ],
        'user': 'grader-course101', # This part has to change to "grader-STBIO440"
        'cwd': '/home/grader-course101' # This part has to 
    }
## 
##########################################################
]
