---
author: minwoo.kim
categories:
  - aws
date: 2022-04-03T17:30:00Z
tags:
  - Django
  - Python
  - DRF
  - JWT
title: 'Django REST framework (DRF) JWT로 로그인 및 회원가입 API 구현 (dj-rest-auth)'
cover:
  image: '/assets/img/drf-with-dj-rest-auth.png'
  alt: 'Django REST framework with JWT, dj-rest-auth'
  relative: false
showToc: true
ShowReadingTime: true
---

[Django](https://www.djangoproject.com/), [Django REST framework](https://www.django-rest-framework.org/)을 이용하여, 로그인 및 회원가입을 구현해보도록 하겠습니다.

최대한 직접 구현하지 않고, 빠르게 구현하는 데 초점을 맞추었습니다.

Django와 관련된 package들을 활용하여 빠르게 로그인 서버를 구축할 수 있습니다.

소스코드는 {{< newtabref href="https://github.com/minuchi/django-auth" title="GitHub" >}}에서 확인해 보실 수 있습니다.

## ⚙️ 00. 환경

- Python: 3.10.3
- Django: 4.0.3
- PC: macOS Monterey 12.3 (M1 2020)

## 🛠 01. 프로젝트 초기 설정

Django 프로젝트 생성을 위해 아래 명령어를 실행합니다.

### Terminal을 이용하여 프로젝트 초기 설정

```bash
# Proejct 폴더 생성
mkdir django-auth && cd django-auth

# django-admin 이 없으면 pip install Django 실행
django-admin startproject api .

# 가상환경 생성
python3 -m venv venv

# 가상환경 실행
source venv/bin/activate

# package 설치
pip install Django
```

### 라이브러리 목록

- Django: Django framwork을 사용하기 위해 설치합니다.

## 🦄 02. Custom User 생성 (email로 로그인)

Custom User를 프로젝트 시작하기 전에 만드는 이유는, 나중에 수정하기 용이합니다. Project 중간에 User Model을 건드리기는 매우 힘듭니다. 따라서 Proejct 시작할 때 해주시는 것이 가장 좋습니다.

로그인 시에 username이 아닌 email을 사용하도록 변경할 예정입니다.

Custom User 생성하기 앞서 아래와 같이 먼저 app을 추가해 줍니다.

### Terminal을 이용하여 accounts app 생성

```python
python manage.py startapp accounts
```

생성된 앱을 `api/settings.py` 에 추가해줍니다.

### `api/settings.py` 에 앱 추가

```python
NSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # 새로 추가한 앱
    'accounts',
]
```

새로 만들 User model을 만들기 앞서 `accounts/managers.py` 에 User Manager를 추가해주고, User Model을 `accounts/models.py` 추가해줍니다.

### `accounts/managers.py` 추가

```python
from django.contrib.auth.base_user import BaseUserManager
from django.utils.translation import gettext_lazy as _

class UserManager(BaseUserManager):
    def create_user(self, email, password, **extra_fields):
        if not email:
            raise ValueError(_('The Email must be set'))
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save()
        return user

    def create_superuser(self, email, password, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError(_('Superuser must have is_staff=True.'))
        if extra_fields.get('is_superuser') is not True:
            raise ValueError(_('Superuser must have is_superuser=True.'))
        return self.create_user(email, password, **extra_fields)
```

### `accounts/models.py` 에 Custom User 추가

```python
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils.translation import gettext_lazy as _

from .managers import UserManager

class User(AbstractUser):
    username = None
    email = models.EmailField(_('email address'), unique=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    objects = UserManager()

    def __str__(self):
        return self.email
```

마지막으로 `api/settings.py` 에 사용하는 User 모델을 선언해줍니다.

### `api/settings.py` 사용할 User 모델 선언

```python
AUTH_USER_MODEL = 'accounts.User'
```

위 같이 설정해주면, User를 이용할 때 더 이상 username이 아닌 email을 사용하여 로그인 및 계정 생성을 진행할 수 있게 됩니다.

### Terminal에서 migrate 수행

```bash
python manage.py makemigrations
python manage.py migrate
```

![drf-first-migration.png](/assets/post/2022/04/04/drf/first-migration.png)

위 명령어 수행 후에 Terminal에서 superuser를 생성해보면, username을 안받는 것을 확인할 수 있습니다.

### Terminal에서 superuser 생성

```bash
python manage.py createsuperuser
```

![drf-create-superuser](/assets/post/2022/04/04/drf/create-superuser.png)

### Terminal에서 서버 실행 및 Django admin 확인

```bash
python manage.py runserver
```

위 명령어를 수행하고, Browser로 [http://localhost:8000/admin/](http://localhost:8000/admin/) 에 접속해봅니다.

![Django admin에서 Email address, Password만 받고 있는 화면](/assets/post/2022/04/04/drf/changed-admin.png)

Django admin에서 Email address, Password만 받고 있는 화면

## 🐍 03. 라이브러리를 활용하여 회원가입 구현하기

우선 필요한 라이브러리들을 설치하도록 합니다.

### Terminal을 이용하여 추가 라이브러리 설치

```bash
# 라이브러리 설치
pip install djangorestframework dj-rest-auth django-allauth djangorestframework-simplejwt
```

### 설치한 라이브러리

- **djangorestframework**: Django를 REST API 형태로 사용할 수 있도록 도와줍니다.
- **dj-rest-auth**: REST API 형태로 제공해주는 로그인, 비밀번호 찾기 등의 기능을 제공합니다. (django-rest-auth라는 라이브러리가 더 이상 개발되지 않음에 따라 생긴 프로젝트)
- **django-allauth**: 회원가입 기능을 제공합니다.
- **djangorestframework-simplejwt**: Django에서 JWT Token을 사용하도록 도와줍니다.

### `api/settings.py` 에 새로 설치한 앱(Package) 추가

```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # 새로 추가한 앱
    'accounts',
    # 설치한 라이브러리들
    'rest_framework',
    'rest_framework.authtoken',
    'dj_rest_auth',
    'django.contrib.sites',
    'allauth',
    'allauth.account',
    'allauth.socialaccount',
    'dj_rest_auth.registration',
]

REST_USE_JWT = True
JWT_AUTH_COOKIE = 'my-app-auth'
JWT_AUTH_REFRESH_COOKIE = 'my-refresh-token'

SITE_ID = 1
ACCOUNT_UNIQUE_EMAIL = True
ACCOUNT_USER_MODEL_USERNAME_FIELD = None
ACCOUNT_USERNAME_REQUIRED = False
ACCOUNT_EMAIL_REQUIRED = True
ACCOUNT_AUTHENTICATION_METHOD = 'email'
ACCOUNT_EMAIL_VERIFICATION = 'none'
```

설치한 라이브러리를 사용할 수 있도록 `api/settings.py` 에 추가해 줍니다.

### 변수 목록

**dj-rest-auth**

- REST_USE_JWT: JWT 사용 여부
- JWT_AUTH_COOKIE: 호출할 Cookie Key값
- JWT_AUTH_REFRESH_COOKIE: Refresh Token Cookie Key 값 (사용하는 경우)

**django-allauth**

- SITE_ID: 해당 도메인의 id (django_site 테이블의 id, oauth 글에서 다룰 예정)
- ACCOUNT_UNIQUE_EMAIL: User email unique 사용 여부
- ACCOUNT_USER_MODEL_USERNAME_FIELD: User username type
- ACCOUNT_USERNAME_REQUIRED: User username 필수 여부
- ACCOUNT_EMAIL_REQUIRED: User email 필수 여부
- ACCOUNT_AUTHENTICATION_METHOD: 로그인 인증 수단
- ACCOUNT_EMAIL_VERIFICATION: Email 인증 필수 여부

### Terminal을 이용하여 새로 추가한 앱에 대해 Migration 수행

```bash
python manage.py migrate
```

추가한 앱들에 대해 migration을 수행합니다.

![drf-migrate-after-installing-packages.png](/assets/post/2022/04/04/drf/migrate-after-installing-packages.png)

migration이 완료되었으면 urls에 회원가입을 할 수 있도록 추가합니다.

### `accounts/urls.py` 추가

```python
from django.urls import path, include

urlpatterns = [
    path('registration/', include('dj_rest_auth.registration.urls')),
]
```

위 urls을 불러 올 수 있도록 `api/urls.py` 에 추가해주도록 합니다.

### `api/urls.py` accounts url 추가

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/accounts/v1/', include('accounts.urls')),
]
```

이렇게 하면 회원가입이 마무리가 되었습니다.

해당 회원가입을 테스트 하기 위해 우선 서버를 실행해줍니다.

### Terminal을 이용하여 서버 실행

```bash
python manage.py runserver
```

위 명령어를 수행하고, [http://localhost:8000/api/accounts/v1/registration](http://localhost:8000/api/accounts/v1/registration) 으로 접속합니다.

위 명령어를 통해 접속하고 API를 테스트 해봅니다.

![drf-api-registration.png](/assets/post/2022/04/04/drf/api-registration.png)
![drf-api-registration-done.png](/assets/post/2022/04/04/drf/api-registration-done.png)

위 화면처럼, 성공하는 것을 알 수 있습니다.

## ☀️ 04. 로그인 구현

여기까지 왔다면, 로그인 구현은 매우 간단합니다. `accounts/urls.py` 를 수정해주도록 합니다.

### `accounts/urls.py`

```python
from django.urls import path, include

urlpatterns = [
    path('', include('dj_rest_auth.urls')), # 해당 라인 추가
    path('registration/', include('dj_rest_auth.registration.urls')),
]
```

위 한 줄만 추가하면, 아래와 같은 URL들을 사용할 수 있게 됩니다.

- [http://localhost:8000/api/accounts/v1/password/reset/](http://localhost:8000/api/accounts/v1/password/reset/)
- [http://localhost:8000/api/accounts/v1/password/reset/confirm/](http://localhost:8000/api/accounts/v1/password/reset/confirm/)
- [http://localhost:8000/api/accounts/v1/login/](http://localhost:8000/api/accounts/v1/login/)
- [http://localhost:8000/api/accounts/v1/logout/](http://localhost:8000/api/accounts/v1/logout/)
- [http://localhost:8000/api/accounts/v1/user/](http://localhost:8000/api/accounts/v1/user/)
- [http://localhost:8000/api/accounts/v1/password/change/](http://localhost:8000/api/accounts/v1/password/change/)
- [http://localhost:8000/api/accounts/v1/token/verify/](http://localhost:8000/api/accounts/v1/token/verify/)
- [http://localhost:8000/api/accounts/v1/token/refresh/](http://localhost:8000/api/accounts/v1/token/refresh/)

### 로그인 테스트

[http://localhost:8000/api/accounts/v1/login/](http://localhost:8000/api/accounts/v1/login/) 에 접속하여, 아까 생성한 계정이 정상적으로 로그인이 되는지 확인해 봅니다.

![drf-api-login.png](/assets/post/2022/04/04/drf/api-login.png)
![drf-api-login-done.png](/assets/post/2022/04/04/drf/api-login-done.png)
![drf-api-login-full.png](/assets/post/2022/04/04/drf/api-login-info.png)
위 화면과 같이 정상적으로 로그인이 되고 있음을 알 수 있습니다.

## 🔚 05. 마무리

Django로 프로젝트를 진행하게 된다면, 여러 패키지(라이브러리)의 도움을 받아 빠르게 API를 구현할 수 있습니다. 하지만 다른 사람이 구현해준 것은 Custom이 힘들다는 단점이 있습니다. 모든 프레임워크, 라이브러리는 취향 또는 필요에 맞게 잘 사용하시면 됩니다.

다음에는 해당 포스트의 연장선으로 Google, Kakao와 같은 로그인 서비스를 연동해보도록 하겠습니다.

감사합니다.

## 📃 06. 참고

- {{< newtabref href="https://www.djangoproject.com/" title="Django" >}}
- {{< newtabref href="https://www.django-rest-framework.org/" title="Django REST framework" >}}
- {{< newtabref href="https://dj-rest-auth.readthedocs.io/en/latest/index.html" title="dj-rest-auth" >}}
- {{< newtabref href="https://django-allauth.readthedocs.io/en/latest/" title="django-all-auth" >}}
- {{< newtabref href="https://testdriven.io/blog/django-custom-user-model/" title="Creating a Custom User Model in Django" >}}
