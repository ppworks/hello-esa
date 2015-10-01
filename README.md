## Hello esa(good-bye Qiita:Team)

`(\( ⁰⊖⁰)/)`

* エクスポートを開始する https://your-team.qiita.com/admin
* Generate new token https://your-team.esa.io/user/tokens/new

## Import Qiita:Team articles

```
bundle exec ruby ./hello_esa.rb <ACCESS_TOKEN> <YOUR_TEAM> <JSON_FILE_PATH>
```

## Create esa.io user

* https://esa.io/signin

## Map Qiita:Team user to esa user

```
bundle exec ruby ./map_user.rb <ACCESS_TOKEN> <YOUR_TEAM> <QIITA_TEAM_USER> <ESA_USER>
```
