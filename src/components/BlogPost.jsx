// src/components/BlogPost.jsx
import React from 'react';

function BlogPost() {
  return (
    <div style={{ margin: '20px', padding: '20px', border: '1px solid #ccc' }}>
      <h2>My First Blog Post</h2>
      <p>This is the content of my very first blog post, built with React and Vite. I'm excited to get this running on S3 and automated with GitHub Actions!</p>
    </div>
  );
}

export default BlogPost;