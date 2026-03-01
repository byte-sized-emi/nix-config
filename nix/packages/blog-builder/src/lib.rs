use chrono::{DateTime, Utc};
use comrak::{Arena, Options, format_html, nodes::NodeValue, parse_document};
use glob::glob;
use minify_html::Cfg;
use serde::{Deserialize, Serialize};

mod templates;
use askama::Template;
use templates::{BlogTemplate, IndexTemplate};

#[derive(Debug, Deserialize, Serialize, PartialEq, Eq)]
pub struct FrontMatter {
    pub title: String,
    pub date: DateTime<Utc>,
    #[serde(default)]
    pub released: bool,
    pub tags: Vec<String>,
    pub authors: Vec<String>,
}

#[derive(Debug, PartialEq, Eq)]
pub struct BlogPost {
    pub name: String,
    pub front_matter: FrontMatter,
    pub html_content: String,
}

pub fn process_website(base_path: &str, output_path: &str) -> Result<(), String> {
    let file_iter =
        glob(format!("{base_path}/posts/*.md").as_str()).expect("Failed to read glob pattern");

    let mut blog_posts = Vec::new();

    for entry in file_iter {
        let path = entry.map_err(|e| format!("Failed to read file entry: {e}"))?;

        println!("Processing {:?}", path.display());
        let contents = std::fs::read_to_string(&path)
            .map_err(|e| format!("Failed to read file {:?}: {e}", path))?;
        let (front_matter, html_content) = process_blogpost(&contents)?;

        let name = path.file_stem().unwrap(); // Remove .md extension

        blog_posts.push(BlogPost {
            name: name.to_string_lossy().to_string(),
            front_matter,
            html_content,
        });
    }

    println!("Processed {} blog post(s)", blog_posts.len());

    let mut released_posts: Vec<_> = blog_posts
        .into_iter()
        .filter(|p| p.front_matter.released)
        .collect();

    released_posts.sort_by_key(|a| a.front_matter.date);
    let released_posts = released_posts;

    println!("Found {} released blog post(s)", released_posts.len());

    std::fs::create_dir_all(format!("{output_path}/posts").as_str())
        .map_err(|e| format!("Failed to create posts directory: {e}"))?;

    // Generate individual blog post pages
    for post in &released_posts {
        let blog_template = BlogTemplate::from_blogpost(post);

        let blog_html = blog_template
            .render()
            .map_err(|e| format!("Failed to render blog template: {e}"))?;

        let output_filename = format!("posts/{}.html", post.name);

        let output_path = format!("{output_path}/{output_filename}");
        save_html_file(&blog_html, &output_path)?;
    }

    let index_template = IndexTemplate {
        title: "byte-sized-emi's blog about...stuff".to_string(),
        posts: released_posts,
    };

    let index_html = index_template
        .render()
        .map_err(|e| format!("Failed to render index template: {e}"))?;

    let output_path = format!("{output_path}/index.html");
    save_html_file(&index_html, &output_path)?;

    Ok(())
}

fn save_html_file(content: &str, output_path: &str) -> Result<(), String> {
    let mut minify_cfg = Cfg::new();
    minify_cfg.minify_css = true;
    let minified = minify_html::minify(content.as_bytes(), &minify_cfg);

    std::fs::write(output_path, minified)
        .map_err(|e| format!("Failed to write to {output_path}: {e}"))?;

    println!("Saved: {output_path}");
    Ok(())
}

pub fn process_blogpost(contents: &str) -> Result<(FrontMatter, String), String> {
    let arena = Arena::new();

    let mut options = Options::default();
    options.extension.front_matter_delimiter = Some("---".to_string());
    options.extension.header_ids = Some("heading-".to_string());
    options.extension.spoiler = true;

    let root = parse_document(&arena, contents.trim(), &options);
    let mut front_matter: Option<FrontMatter> = None;

    for node in root.descendants() {
        if let NodeValue::FrontMatter(fm) = &node.data().value {
            let fm_without_delimiters = fm.trim().trim_start_matches("---").trim_end_matches("---");
            let fm = yaml_serde::from_str(&fm_without_delimiters)
                .map_err(|e| format!("Failed to parse front matter: {e}"))?;
            front_matter = Some(fm);
        }
    }

    let Some(front_matter) = front_matter else {
        Err("File is missing frontmatter".to_string())?
    };

    let mut html_content = String::new();
    format_html(root, &options, &mut html_content).unwrap();

    Ok((front_matter, html_content))
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::DateTime;
    use similar_asserts::assert_eq;

    #[test]
    fn test_simple_case() -> Result<(), String> {
        let contents = "
---
title: My Title
date: 2024-01-02T00:00:00+01:00
tags: [tag1, tag2]
authors: [Author One, Author Two]
---

# This is a file containing markdown content.

This is normal content, with a ||spoiler||.

*wow*
**incredible**
        ";

        println!("Contents:\n{contents}");

        let expected_front_matter = FrontMatter {
            title: "My Title".to_string(),
            date: DateTime::parse_from_rfc3339("2024-01-01T23:00:00Z")
                .unwrap()
                .to_utc(),
            released: false,
            tags: vec!["tag1".to_string(), "tag2".to_string()],
            authors: vec!["Author One".to_string(), "Author Two".to_string()],
        };

        let result = process_blogpost(contents)?;

        assert_eq!(result.0, expected_front_matter);

        assert_eq!(
            result.1,
            r##"<h1><a href="#this-is-a-file-containing-markdown-content" aria-hidden="true" class="anchor" id="heading-this-is-a-file-containing-markdown-content"></a>This is a file containing markdown content.</h1>
<p>This is normal content, with a <span class="spoiler">spoiler</span>.</p>
<p><em>wow</em>
<strong>incredible</strong></p>
"##
        );

        Ok(())
    }
}
