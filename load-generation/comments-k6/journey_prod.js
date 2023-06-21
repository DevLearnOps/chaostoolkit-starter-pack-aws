import http from 'k6/http';
import { SharedArray } from 'k6/data';
import { sleep } from 'k6';

const users = new SharedArray('users', function() {
    const data = JSON.parse(open('../users.json'));
    return data;
});
const posts = new SharedArray('posts', function() {
    const data = JSON.parse(open('../posts.json'));
    return data;
});
const comments = new SharedArray('comments', function() {
    const data = JSON.parse(open('../comments.json'));
    return data;
});
const host = __ENV.COMMENTS_URL ? __ENV.COMMENTS_URL : 'http://localhost:3000';
const params = {
    headers: {
    'Content-Type': 'application/json',
    },
};

export function setup() {
    console.log(`Loaded ${users.length} users from file.`)
    console.log(`Loaded ${posts.length} posts from file.`)
    console.log(`Loaded ${comments.length} comments from file.`)
}

function targetPercent(percent) {
    const rand = Math.floor(Math.random() * 100);
    return rand <= percent;
}

function pickRand(data) {
    return data[Math.floor(Math.random() * data.length)];
}

function createIfNotExists(type, payload) {
    let response = http.get(`${host}/${type}/${payload.id}`);
    if (response.status === 404) {
        response = http.post(`${host}/${type}/`, JSON.stringify(payload), params);
    }

    const newId = JSON.parse(response.body).id;
    return newId
}
  
export default function (data) {

    // Setup user
    // Creates user from list if doesn't exist
    let user = pickRand(users)
    let userId = createIfNotExists('users', user);

    http.get(`${host}/users/${userId}`);
    
    if(targetPercent(4)) {
        let updateUserPayload = JSON.stringify({
            handle: user.handle,
            username: "New " + user.username
        });
        
        http.put(`${host}/users/${userId}`, updateUserPayload, params);
    }


    // Setup post
    // Creates post from list if doesn't exist and runs post information update if needed
    // according to load target percentage
    let post = pickRand(posts)
    let postId = createIfNotExists('posts', post);

    if(targetPercent(15)) {
        let updateData = {id: postId, url: 'https://www.test.com/permalink', title: 'Updated post title'};
        
        http.put(`${host}/posts/${postId}`, JSON.stringify(updateData), params);
    }
    http.get(`${host}/posts/${postId}`);

       
    // Post and update comments
    // Creates and or updates comments according to load target percentages
    http.get(`${host}/comments`);

    if (targetPercent(40)) {
        let commentPayload = {
            content: pickRand(comments).content,
            user: userId,
            replyTo: null,
            post: postId
        };

        let response = http.post(`${host}/comments/`, JSON.stringify(commentPayload), params);
        
        if(response.status !== 200) {
            console.log(`Failed to post comment. Status ${response.status}`);
            return;
        }

        const commentId = JSON.parse(response.body).id;

        http.get(`${host}/comments/${commentId}`);

        if (targetPercent(20)) {
            commentPayload = JSON.stringify({
                content: pickRand(comments).content
            });
            http.put(`${host}/comments/${commentId}`, JSON.stringify(commentPayload), params);

            http.get(`${host}/comments/${commentId}`);
        }

        sleep(1);
        if(targetPercent(20) && commentId !== undefined) {
            http.del(`${host}/comments/${commentId}`);
        }
    }

    sleep(1);
    if(targetPercent(1) && postId !== undefined) {
        http.del(`${host}/posts/${postId}`);
    }
  }
  
  export function teardown(data) {
  }
