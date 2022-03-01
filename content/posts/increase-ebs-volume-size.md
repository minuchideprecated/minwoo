---
author: minwoo.kim
categories:
  - aws
date: 2021-12-21T11:33:00Z
tags:
  - AWS
  - EC2
  - EBS
title: 'AWS EC2 용량 증설 (EBS 볼륨 확장)'
cover:
  image: '/assets/img/aws-smile.jpg'
  alt: 'AWS Smile'
  relative: false
---

## AWS Console 작업

### 작업 순서

1. EC2 메뉴로 이동합니다.
2. 용량을 증설할 서버를 선택 후 Storage 메뉴에서 증설할 Volume ID를 눌러 이동합니다.
3. EBS (Elastic Block Store)의 Volumes 메뉴로 이동됨을 확인합니다.
4. 선택된 Volume의 Actions를 눌러 Modify Volume를 클릭합니다.

   ![EBS(Elastic Block Store)의 Volumes에서 Actions를 선택하였을 때 화면](/assets/post/13a83ebe-b98f-555f-8a50-fd6b43441462.png)

   EBS(Elastic Block Store)의 Volumes에서 Actions를 선택하였을 때 화면

5. 모달 창이 떴다면, Size 값을 변경하고 싶은 값으로 변경하고 **Modify** 버튼을 눌러 진행합니다. (GiB 기준)

   ![Volume Size 변경 화면](/assets/post/a0bc4b57-e349-55f2-a8b5-d9cc14ba8ee9.png)

   Volume Size 변경 화면

6. 확인 창이 나오는데, 해당 내용에 문제가 없다면 **Yes** 버튼을 눌러 진행합니다.

   ![Volume 수정 확인 화면](/assets/post/75896c67-8a45-5138-9a48-0fd0215b55ff.png)

   Volume 수정 확인 화면

위와 같이 진행하면 AWS Console에서의 작업은 완료되었습니다. 해당 Volume의 State 값이 완료될 때 까지 기다린 후 Server 에서의 작업을 마저 진행하시면 됩니다.

![Volume State 예시 화면](/assets/post/4f650733-2f70-58d5-aa08-904dbfd70a90.png)

Volume State 예시 화면

### 참조 링크

- [EBS 볼륨에 대한 수정 요청 (한국어)](https://docs.aws.amazon.com/ko_kr/AWSEC2/latest/UserGuide/requesting-ebs-volume-modifications.html)
- [Request modifications to your EBS volumes (English)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/requesting-ebs-volume-modifications.html)

## AWS Server 작업 (Ubuntu 20.04 기준)

### 작업 순서

```bash
lsblk
```

위 명령어로 우선 사용하고 있는 디스크의 이름 및 용량을 조회합니다.

Ubuntu의 경우 **nvme0n1** 입니다.

```bash
sudo growpart /dev/nvme0n1 1
```

위 명령어로 볼륨 마운트를 진행합니다.

```bash
df -hT
```

아래 명령어로 볼륨 타입에 맞게 볼륨을 늘려주면 됩니다.

**XFS**

```bash
sudo xfs_growfs -d /
```

**ext4**

```bash
sudo resize2fs /dev/nvme0n1
```

### 참조 링크

- {{< newtabref href="https://docs.aws.amazon.com/ko_kr/AWSEC2/latest/UserGuide/recognize-expanded-volume-linux.html" title="볼륨 크기 조정 후 Linux 파일 시스템 확장 (한국어)" >}}
- {{< newtabref href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/recognize-expanded-volume-linux.html" title="Extend a Linux file system after resizing a volume (English)" >}}
