import http from 'k6/http';
import {
    sleep
} from 'k6';

export default function(data) {
    const host = __ENV.COMMENTS_URL ? __ENV.COMMENTS_URL : 'http://localhost:3000';

    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
    };

    // USERS

    http.get(`${host}/users`);

    let payload_user = JSON.stringify({
        handle: '@test_user',
        username: 'Test user',
    });

    let response = http.post(`${host}/users/`, payload_user, params);

    const user_id = JSON.parse(response.body).id;

    http.get(`${host}/users/${user_id}`);

    payload_user = JSON.stringify({
        handle: '@newuser',
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

    const post_id = JSON.parse(response.body).id;

    http.get(`${host}/posts/${post_id}`);

    let updateData = {
        id: post_id,
        url: 'https://www.test.com/permalink',
        title: 'Updated post title'
    };

    http.put(`${host}/posts/${post_id}`, JSON.stringify(updateData), params);

    http.get(`${host}/posts/${post_id}`);

    // COMMENTS

    http.get(`${host}/comments`);

    let payload_spam_comment = JSON.stringify({
        content: "Contact me now to get a free loan!",
        user: user_id,
        replyTo: null,
        post: post_id
    });

    response = http.post(`${host}/comments/`, payload_spam_comment, params);

    let payload_comment = JSON.stringify({
        content: "I really like your article!",
        user: user_id,
        replyTo: null,
        post: post_id
    });

    response = http.post(`${host}/comments/`, payload_comment, params);

    const comment_id = JSON.parse(response.body).id;

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