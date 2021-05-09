# CLICKBAIT-FILTER-SCHEDULER

[![ClickBaitSite](https://click-bait-filtering-plugin.com/assets/images/icon-128-122x122.png)](https://click-bait-filtering-plugin.com/index.html)

## Description

This application is a part of a group of services who plot to rid the web of clickbait by relying on user input and machine learning. The completed application functions by storing it’s user clicked items and using them to disseminate what is clickbait and what is legitimate news, stories, etc. This is done in conjunction with a machine learning classificator. The full application functions on all sites and thus can allow you to be more productive while browsing the web. This happens by providing you user with a slider giving him possibility to filter content, deemed clickbait and at the same time highlight content that is deemed not. In addition it can show it’s user the topology of the most clickbaity content of each domain.
</br>
</br>
This Django service is a Tensorflow Model generator and DB Source Updater for production. For more info visit the application [CLICKBAIT-PORTAL] and download the build of this plugin from the [CHROME-STORE].

## Technologies

CLICKBAIT-FILTER-ML uses a number of open source projects:

  * [PYTHON] - PYTHON
  * [DJANGO] - PYTHON WEB FRAMEWORK
  * [TENSOR-FLOW] - MACHINE LEARNING LIBRARY
  * [KERAS] - MACHINE LEARNING FRAMEWORK
  * [NUMPY] - SCIENTIFIC COMPUTING LIB
  * [POSTGRES] - OPEN SOURCE SQL DATABASE

## Applications Scopes

This service is a part of a multi application project that features the following git repositories:

| Service Name                                  | Description                         | Maintainer              |
| ----------------------------------------      |:------------------------------------|:------------------------|
| [click_bait_filter_extension]                 | Chrome Extensions Plugin            | [LeadShuriken]          |
| [click_bait_filter_be]\(TEST_SERVER)          | Node Application Test Server        | [LeadShuriken]          |
| [click_bait_filter_j]                         | Spring Production Server            | [LeadShuriken]          |
| [click_bait_filter_tflow]                     | Java TensorFlow Server              | [LeadShuriken]          |
| [click_bait_filter_nlp]                       | ML Model Development Environment    | [LeadShuriken]          |
| [click_bait_filter_portal]                    | Service and Information Portal      | [LeadShuriken]          |
| [click_bait_filter_scheduler]                 | Database Scheduler ML Model Builder | [LeadShuriken]          |

For development the application should have the following structure:
```sh
 | .
 | +-- click_bait_filter_extension
 | +-- click_bait_filter_be
 | +-- click_bait_filter_j
 | +-- click_bait_filter_tflow
 | +-- click_bait_filter_nlp
 | +-- click_bait_filter_portal
 | +-- click_bait_filter_scheduler
```

## Installation

CLICKBAIT-FILTER-SCHEDULER requires [Python](https://www.python.org) v3.6+ to run.

To setup the python environments install `virtualenv` (venv) for the python and:

1. Create a virtual environment `$ virtualenv venv`
2. Activate virtual environment `$ source venv/bin/activate`

To install the python dependancies:

1. Make sure virtual environment is activated
2. `$ pip install -r requirements.txt`
3. Done∂

### MODEL

![alt text](https://github.com/LeadShuriken/click_bait_filter_ml/blob/develop/model.png?raw=true)

### DATABASE

![alt text](https://github.com/LeadShuriken/click_bait_filter_j/blob/master/database.png?raw=true)
 
  [PYTHON]: <https://www.python.org>
  [KERAS]: <https://github.com/keras-team/keras>
  [NUMPY]: <https://github.com/numpy/numpy>
  [DJANGO]: <https://www.djangoproject.com>
  [POSTGRES]: <https://www.postgresql.org>
  [TENSOR-FLOW]: <https://www.tensorflow.org>

  [click_bait_filter_extension]: <https://github.com/LeadShuriken/click_bait_filter_extension>
  [click_bait_filter_be]: <https://github.com/LeadShuriken/click_bait_filter_be>
  [click_bait_filter_nlp]: <https://github.com/LeadShuriken/click_bait_filter_nlp>
  [click_bait_filter_portal]: <https://github.com/LeadShuriken/click_bait_filter_portal>
  [click_bait_filter_j]: <https://github.com/LeadShuriken/click_bait_filter_j>
  [click_bait_filter_tflow]: <https://github.com/LeadShuriken/click_bait_filter_tflow>

  [LeadShuriken]: <https://github.com/LeadShuriken>

  [CHROME-STORE]: <https://chrome.google.com/webstore/detail/clickbait-filtering-plugi/mgebfihfmenffogbbjlcljgaedfciogm>
  [CLICKBAIT-PORTAL]: <https://click-bait-filtering-plugin.com>

  [MONGO CONNECTION STRING]: <https://docs.mongodb.com/manual/reference/connection-string>
