local HAS_RUNNER = not not lunit
local lunit      = require "lunit"
local TEST_CASE  = assert(lunit.TEST_CASE)
local skip       = lunit.skip or function() end
local curl       = require "lcurl"

local _ENV = TEST_CASE'add_content' do

local post

function setup()
  post = curl.form()
end

function teardown()
  if post then post:free() end
  post = nil
end

local function F(...)
  local data = assert_string(post:get())
  post:free()
  post = nil
  return data
end

function test_01()
  assert_equal(post, post:add_content('name01', 'value01'))
  local data = assert_string(post:get())
  assert_match("\r\n\r\nvalue01\r\n", data)
  assert_match('name="name01"', data)
end

function test_02()
  assert_equal(post, post:add_content('name02', 'value02', "text/plain"))
  local data = assert_string(post:get())
  assert_match("\r\n\r\nvalue02\r\n", data)
  assert_match('name="name02"', data)
  assert_match('Content%-Type: text/plain\r\n', data)
end

function test_03()
  assert_equal(post, post:add_content('name03', 'value03', {"Content-Encoding: gzip"}))
  local data = assert_string(post:get())
  assert_match("\r\n\r\nvalue03\r\n", data)
  assert_match('name="name03"', data)
  assert_match('Content%-Encoding: gzip\r\n', data)
end

function test_04()
  assert_equal(post, post:add_content('name04', 'value04', "text/plain", {"Content-Encoding: gzip"}))
  local data = assert_string(post:get())
  assert_match("\r\n\r\nvalue04\r\n", data)
  assert_match('name="name04"', data)
  assert_match('Content%-Encoding: gzip\r\n', data)
  assert_match('Content%-Type: text/plain\r\n', data)
end

end

local _ENV = TEST_CASE'add_buffer' do

local post

function setup()
  post = curl.form()
end

function teardown()
  if post then post:free() end
  post = nil
end

function test_01()
  assert_equal(post, post:add_buffer('name01', 'file01', 'value01'))
  local data = assert_string(post:get())
  assert_match("\r\n\r\nvalue01\r\n", data)
  assert_match('name="name01"', data)
  assert_match('filename="file01"', data)
  assert_match('Content%-Type: application/octet%-stream\r\n', data)
end

function test_02()
  assert_equal(post, post:add_buffer('name02', 'file02', 'value02', "text/plain"))
  local data = assert_string(post:get())
  assert_match("\r\n\r\nvalue02\r\n", data)
  assert_match('name="name02"', data)
  assert_match('filename="file02"', data)
  assert_match('Content%-Type: text/plain\r\n', data)
  assert_not_match('Content%-Type: application/octet%-stream\r\n', data)
end

function test_03()
  assert_equal(post, post:add_buffer('name03', 'file03', 'value03', {"Content-Encoding: gzip"}))
  local data = assert_string(post:get())
  assert_match("\r\n\r\nvalue03\r\n", data)
  assert_match('name="name03"', data)
  assert_match('filename="file03"', data)
  assert_match('Content%-Type: application/octet%-stream\r\n', data)
  assert_match('Content%-Encoding: gzip\r\n', data)
end

function test_04()
  assert_equal(post, post:add_buffer('name04', 'file04', 'value04', "text/plain", {"Content-Encoding: gzip"}))
  local data = assert_string(post:get())
  assert_match("\r\n\r\nvalue04\r\n", data)
  assert_match('name="name04"', data)
  assert_match('filename="file04"', data)
  assert_match('Content%-Type: text/plain\r\n', data)
  assert_not_match('Content%-Type: application/octet%-stream\r\n', data)
  assert_match('Content%-Encoding: gzip\r\n', data)
end


function test_05()
  assert_equal(post, post:add_buffer('name05', 'file05', 'value05', nil, {"Content-Encoding: gzip"}))
  local data = assert_string(post:get())
  assert_match("\r\n\r\nvalue05\r\n", data)
  assert_match('name="name05"', data)
  assert_match('filename="file05"', data)
  assert_match('Content%-Type: application/octet%-stream\r\n', data)
  assert_match('Content%-Encoding: gzip\r\n', data)
end

end

if not HAS_RUNNER then lunit.run() end