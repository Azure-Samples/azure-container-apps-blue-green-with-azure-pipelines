var router = require("../routes/index");
var express = require("express");
var request = require("supertest");

const app = new express();
app.use('/', router);

describe('Good Home Routes', function () {

  test('responds to /', async () => {
    const res = await request(app).get('/');
    expect(res.header['content-type']).toBe('text/html; charset=utf-8');
    expect(res.statusCode).toBe(500);
    //TODO: revisit this test
    //expect(res.text).toEqual('hello world!');
  });
  

});