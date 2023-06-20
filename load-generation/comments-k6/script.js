// 1. init code
import http from 'k6/http';
import { sleep } from 'k6';


export function setup() {
    // 2. setup code
  }
  
  export default function (data) {
    // 3. VU code
    const host = __ENV.COMMENTS_URL ? __ENV.COMMENTS_URL : 'http://localhost:3000';

    const params = {
        headers: {
        'Content-Type': 'application/json',
        },
    };

    // USERS

    http.get(`${host}/users`);

    let payload_user = JSON.stringify({
        handle: 'test_user',
        username: 'Test user',
    });

    let response = http.post(`${host}/users/`, payload_user, params);

    const user_id = response.body.id;

    http.get(`${host}/users/${user_id}`);

    payload_user = JSON.stringify({
        username: 'New username',
    });
    
    http.put(`${host}/users/${user_id}`, payload_user, params);

    http.get(`${host}/users/${user_id}`);
 
    // POSTS

    http.get(`${host}/posts`);

    let payload_post = JSON.stringify({
        url: 'https://www.test.com',
        title: 'Test post',
    });

    response = http.post(`${host}/posts/`, payload_post, params);

    const post_id = response.body.id;

    http.get(`${host}/posts/${post_id}`);

    payload_post = JSON.stringify({
        title: 'New title',
    });
    
    http.put(`${host}/posts/${post_id}`, payload_post, params);

    http.get(`${host}/posts/${post_id}`);

    // COMMENTS
       
    http.get(`${host}/comments`);

    let payload_spam_comment = JSON.stringify({
        content: "Contact me now to get a free loan!",
        user: 1,
        replyTo: null,
        post: 1
    });

    response = http.post(`${host}/comments/`, payload_spam_comment, params);

    let payload_comment = JSON.stringify({
        content: "I really like your article!",
        user: 1,
        replyTo: null,
        post: 1
    });

    response = http.post(`${host}/comments/`, payload_comment, params);

    const comment_id = response.body.id;

    http.get(`${host}/comments/${comment_id}`);

    payload_comment = JSON.stringify({
        content: 'Goodbye!',
    });
    
    http.put(`${host}/comments/${comment_id}`, payload_comment, params);

    http.get(`${host}/comments/${comment_id}`);

    // DELETE

    sleep(1);

    http.del(`${host}/comments/${comment_id}`);
    http.del(`${host}/posts/${post_id}`);
    http.del(`${host}/users/${user_id}`);
  }
  
  export function teardown(data) {
    // 4. teardown code
  }
