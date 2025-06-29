#!/bin/bash

API_URL="http://localhost:8080/api/v1/users"
USERNAME="testuser$RANDOM"
EMAIL="test${RANDOM}@example.com"
PASSWORD="123456"
NICKNAME="测试用户"
NEW_NICKNAME="新昵称"
WRONG_PASSWORD="wrongpass"
FAKE_TOKEN="Bearer faketoken.123456.abcdef"

echo "== 注册 =="
register_resp=$(curl -s -X POST $API_URL/register \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"nickname\":\"$NICKNAME\"}")
echo "$register_resp"

echo "== 重复注册（应失败） =="
register_dup=$(curl -s -X POST $API_URL/register \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"nickname\":\"$NICKNAME\"}")
echo "$register_dup"

echo "== 登录 =="
login_resp=$(curl -s -X POST $API_URL/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}")
echo "$login_resp"

token=$(echo $login_resp | grep -o '"token":"[^"]*' | grep -o '[^"]*$')
if [ -z "$token" ]; then
  echo "登录失败，无法获取token，测试终止"
  exit 1
fi

echo "== 错误密码登录（应失败） =="
login_wrong=$(curl -s -X POST $API_URL/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$WRONG_PASSWORD\"}")
echo "$login_wrong"

echo "== 获取当前用户信息（无Token，应失败） =="
me_no_token=$(curl -s -X GET $API_URL/me)
echo "$me_no_token"

echo "== 获取当前用户信息（伪造Token，应失败） =="
me_fake_token=$(curl -s -X GET $API_URL/me -H "Authorization: $FAKE_TOKEN")
echo "$me_fake_token"

echo "== 获取当前用户信息（正常） =="
me_resp=$(curl -s -X GET $API_URL/me -H "Authorization: Bearer $token")
echo "$me_resp"

echo "== 更新用户信息（正常） =="
update_resp=$(curl -s -X PUT $API_URL/me \
  -H "Authorization: Bearer $token" \
  -H "Content-Type: application/json" \
  -d "{\"nickname\":\"$NEW_NICKNAME\"}")
echo "$update_resp"

echo "== 更新用户信息（无Token，应失败） =="
update_no_token=$(curl -s -X PUT $API_URL/me \
  -H "Content-Type: application/json" \
  -d "{\"nickname\":\"$NEW_NICKNAME\"}")
echo "$update_no_token"

echo "== 更新用户信息（参数错误，应失败） =="
update_bad_json=$(curl -s -X PUT $API_URL/me \
  -H "Authorization: Bearer $token" \
  -H "Content-Type: application/json" \
  -d '{"nickname":123}') # nickname 应为字符串
echo "$update_bad_json"

echo "== 登出 =="
logout_resp=$(curl -s -X POST $API_URL/logout -H "Authorization: Bearer $token")
echo "$logout_resp"

echo "== 登出后再次获取用户信息（应失败） =="
me_after_logout=$(curl -s -X GET $API_URL/me -H "Authorization: Bearer $token")
echo "$me_after_logout"