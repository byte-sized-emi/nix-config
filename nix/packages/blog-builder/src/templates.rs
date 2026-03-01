use askama::Template;
use chrono::{DateTime, Utc};

use crate::BlogPost;

#[derive(Template)]
#[template(path = "index.html")]
pub struct IndexTemplate {
    pub title: String,
    pub posts: Vec<BlogPost>,
}

#[derive(Template)]
#[template(path = "blog.html")]
pub struct BlogTemplate {
    pub title: String,
    pub date: DateTime<Utc>,
    pub authors: Vec<String>,
    pub tags: Vec<String>,
    pub content: String,
}

impl BlogTemplate {
    pub fn from_blogpost(post: &BlogPost) -> Self {
        Self {
            title: post.front_matter.title.clone(),
            date: post.front_matter.date,
            authors: post.front_matter.authors.clone(),
            tags: post.front_matter.tags.clone(),
            content: post.html_content.clone(),
        }
    }
}
