#!/bin/bash

API_URL="http://localhost:8080/api/v1/users"
RAND_SUFFIX=$(date +%s%N | md5sum | cut -c1-8)
USERNAME="testuser_$RAND_SUFFIX"
EMAIL="test_$RAND_SUFFIX@example.com"
PASSWORD="123456"
NICKNAME="测试用户"
NEW_NICKNAME="新昵称"
WRONG_PASSWORD="wrongpass"
FAKE_TOKEN="Bearer faketoken.123456.abcdef"

pass=0
fail=0

function assert_contains() {
  local resp="$1"
  local expect="$2"
  local msg="$3"
  if echo "$resp" | grep -q "$expect"; then
    echo "✅ $msg"
    pass=$((pass+1))
  else
    echo "❌ $msg"
    echo "  响应: $resp"
    fail=$((fail+1))
  fi
}

echo "== 注册 =="
register_resp=$(curl -s -X POST $API_URL/register \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"nickname\":\"$NICKNAME\"}")
assert_contains "$register_resp" '"code":201' "注册成功"

echo "== 重复注册（应失败） =="
register_dup=$(curl -s -X POST $API_URL/register \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"nickname\":\"$NICKNAME\"}")
assert_contains "$register_dup" '"code":409' "重复注册返回409"

echo "== 登录 =="
login_resp=$(curl -s -X POST $API_URL/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}")
assert_contains "$login_resp" '"code":200' "登录成功"

token=$(echo $login_resp | grep -o '"token":"[^"]*' | grep -o '[^"]*$')
if [ -z "$token" ]; then
  echo "❌ 登录失败，无法获取token，测试终止"
  exit 1
fi

echo "== 错误密码登录（应失败） =="
login_wrong=$(curl -s -X POST $API_URL/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$WRONG_PASSWORD\"}")
assert_contains "$login_wrong" '"code":401' "错误密码登录返回401"

echo "== 获取当前用户信息（无Token，应失败） =="
me_no_token=$(curl -s -X GET $API_URL/me)
assert_contains "$me_no_token" '"code":401' "无Token获取用户信息返回401"

echo "== 获取当前用户信息（伪造Token，应失败） =="
me_fake_token=$(curl -s -X GET $API_URL/me -H "Authorization: $FAKE_TOKEN")
assert_contains "$me_fake_token" '"code":401' "伪造Token获取用户信息返回401"

echo "== 获取当前用户信息（正常） =="
me_resp=$(curl -s -X GET $API_URL/me -H "Authorization: Bearer $token")
assert_contains "$me_resp" '"code":200' "正常获取用户信息"

echo "== 更新用户信息（正常） =="
update_resp=$(curl -s -X PUT $API_URL/me \
  -H "Authorization: Bearer $token" \
  -H "Content-Type: application/json" \
  -d "{\"nickname\":\"$NEW_NICKNAME\"}")
assert_contains "$update_resp" '"code":200' "正常更新用户信息"

echo "== 更新用户信息（无Token，应失败） =="
update_no_token=$(curl -s -X PUT $API_URL/me \
  -H "Content-Type: application/json" \
  -d "{\"nickname\":\"$NEW_NICKNAME\"}")
assert_contains "$update_no_token" '"code":401' "无Token更新用户信息返回401"

echo "== 更新用户信息（参数错误，应失败） =="
update_bad_json=$(curl -s -X PUT $API_URL/me \
  -H "Authorization: Bearer $token" \
  -H "Content-Type: application/json" \
  -d '{"nickname":123}') # nickname 应为字符串
assert_contains "$update_bad_json" '"code":400' "参数错误更新用户信息返回400"

echo "== 登出 =="
logout_resp=$(curl -s -X POST $API_URL/logout -H "Authorization: Bearer $token")
assert_contains "$logout_resp" '"code":200' "登出成功"

echo "== 登出后再次获取用户信息（应失败） =="
me_after_logout=$(curl -s -X GET $API_URL/me -H "Authorization: Bearer $token")
assert_contains "$me_after_logout" '"code":401' "登出后Token失效"

echo
echo "测试通过: $pass"
echo "测试失败: $fail"

if [ "$fail" -eq 0 ]; then
  echo "🎉 所有用户系统接口测试全部通过！"
else
  echo "❗ 存在失败用例，请检查上方输出。"
fi