# Applied_bioinfo_nbgrader
An instruction to configure nbgrader on jupyterhub.scripps for Applied_Bioinfo class in 2020 fall.

## Dependencies
The instruction was tested on `flexlm` node with following required software and packages:

- R & R packages
    - IR kernel
    - testthat
    - stringr
- Jupyter
- nbgrader
    - nbgrader Formgrader extension
    
  
## How to run
Run the following command as `root`. `cd` to this folder. By default we will create a course named `abcb2020` with an single instructor named `instructor-abcb2020`.


### Step 0a: create an instructor account
We need a new instructor account called `instructor-abcb2020` - either by the following script (then the password would be the same) or not
```ruby
make_user () {
    local user="${1}"
    echo "Creating user '${user}'"
    useradd "${user}"
    yes "${user}" | passwd "${user}"
    mkdir "/home/${user}"
    chown "${user}:${user}" "/home/${user}"
}

make_user instructor-abcb2020
```


### Step 0b: modify nbgrader_config file
Modify nbgrader configuration files. Check the 2 files existed in this repo, they will be used in the following steps:
- __instructor_nbgrader_config.py__ (used by `setup_nbgrader` function in __util.sh__)
```ruby
c = get_config()

c.CourseDirectory.root = '/home/instructor-abcb2020/abcb2020'
```
Note: The course directory has to match the course name under instructor's account.

- __jupyterhub_config.py__ (used by `setup_jupyterhub` function in __util.sh__)
```ruby
c = get_config()

c.Authenticator.whitelist = [
    'instructor-abcb2020',
    # add all the student account here...
    # 'student1',
    # 'student2',
    # 'student3'
]
```
Note: Update the user list when new students joined...


### Step 1: assign variables
```ruby
# Configuration variables.
root="/root"
srv_root="/srv/nbgrader"
nbgrader_root="/srv/nbgrader/nbgrader"
jupyterhub_root="/srv/nbgrader/jupyterhub"
exchange_root="/srv/nbgrader/exchange"
```

### Step 2: import helper functions
```ruby
source utils.sh
```


### Step 3: reset nbgrader / disable all the extensions
```ruby
setup_directory "${srv_root}" ugo+r
init_nbgrader "${nbgrader_root}" "${exchange_root}"
setup_jupyterhub "${jupyterhub_root}"
```


### Step 4: create the course
```ruby
setup_nbgrader instructor-abcb2020 instructor_nbgrader_config.py
create_course instructor-abcb2020 abcb2020
```


### Step 5: enable extensions for the instructor
```ruby
# Enable extensions for instructor.
enable_create_assignment instructor-abcb2020
enable_formgrader instructor-abcb2020
enable_assignment_list instructor-abcb2020
```


### Step 6: enable assignment list for the students
Update the `students` list whenever new students joining...
```ruby
students=(student1 student2 student3)

for student in ${students[@]}; do
    enable_assignment_list "${student}"
done
```
Note: Be careful not to include the `instructor-abcb2020` to the `students` list, if so, rerun from __Step 2__ but skip __Step 4__. 


### Maintenance: when new student join
- Update the whitelist in __jupyterhub_config.py__
- Rerun __Step 0b__,  __Step 2__, __Step 3__, __Step 5__, and __Step 6__ (with corresponding __students__ list in Step 6.) 
