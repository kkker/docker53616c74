



```
mkdir tst
composer create-project fuel/fuel:1.8.1 --prefer-source .
php oil refine install
```

```
cd ~/code/demo/backend
php oil g controller hell world

ubuntu@b9e881f5889d:~/code/demo/backend$ php oil g controller hell world
        Creating view: /home/ubuntu/code/demo/backend/fuel/app/views/template.php
        Creating view: /home/ubuntu/code/demo/backend/fuel/app/views/hell/world.php
        Creating controller: /home/ubuntu/code/demo/backend/fuel/app/classes/controller/hell.php
```



