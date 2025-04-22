// src/App.jsx
import React from 'react';
import './App.css';

const blogData = {
  title: 'My Awesome Single-Page Blog',
  sections: [
    {
      title: 'First Thoughts on a New Adventure',
      date: 'April 15, 2025',
      content: `
        <p>This is the beginning of something exciting! I'm thrilled to share my initial thoughts as I embark on this new adventure. Stay tuned for more updates.</p>
        <p>I'm planning to document my progress and share any insights I gain along the way. It's going to be a journey filled with learning and growth.</p>
      `,
    },
    {
      title: 'Diving Deeper into the Details',
      date: 'April 17, 2025',
      content: `
        <p>Today, I delved deeper into the specifics of the project. There are some interesting challenges ahead, but I'm feeling motivated and ready to tackle them.</p>
        <ul>
          <li>Researching key technologies</li>
          <li>Outlining the initial steps</li>
          <li>Brainstorming potential solutions</li>
        </ul>
      `,
    },
    {
      title: 'Overcoming the First Hurdle',
      date: 'April 19, 2025',
      content: `
        <p>I encountered my first significant obstacle today, but after some persistent effort, I managed to overcome it! This experience has been a valuable learning opportunity.</p>
        <p>The key was breaking down the problem into smaller, more manageable parts. It's amazing what you can achieve with a systematic approach.</p>
      `,
    },
  ],
};

function App() {
  return (
    <div className="blog-container">
      <header className="blog-header">
        <h1>{blogData.title}</h1>
      </header>

      <nav className="table-of-contents">
        <h2>Table of Contents</h2>
        <ul>
          {blogData.sections.map((section, index) => (
            <li key={index}>
              <a href={`#section-${index}`}>{section.title}</a>
            </li>
          ))}
        </ul>
      </nav>

      <main className="blog-content">
        {blogData.sections.map((section, index) => (
          <section id={`section-${index}`} key={index} className="blog-section">
            <h2 className="section-title">{section.title}</h2>
            <p className="date-header">{section.date}</p>
            <div className="section-content" dangerouslySetInnerHTML={{ __html: section.content }} />
          </section>
        ))}
      </main>

      <footer className="blog-footer">
        <p>&copy; 2025 My Awesome Blog</p>
      </footer>
    </div>
  );
}

export default App;