# Claude Dispatch

<!-- START doctoc generated TOC please keep comment here to allow auto update -->

**Table of Contents**  *generated with [DocToc](https://github.com/ktechhub/doctoc)*

<!---toc start-->

* [Claude Dispatch](#claude-dispatch)
  * [1. What is Claude Dispatch?](#1-what-is-claude-dispatch)
  * [2. How It Works](#2-how-it-works)
  * [3. Requirements](#3-requirements)
  * [4. Getting Started](#4-getting-started)
  * [5. What You Can Do](#5-what-you-can-do)
  * [6. Current Limitations](#6-current-limitations)

<!---toc end-->

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



## 1. What is Claude Dispatch?

Claude Dispatch is a feature inside Cowork that gives you one continuous conversation with Claude that you can reach from your phone or your desktop. You assign Claude a task, go do something else, and come back to the finished work. Claude runs on your computer with access to your local files, connectors, plugins, and your apps through computer use. It messages you the result when it's done.

Available as a research preview in Cowork on Pro and Max plans. Requires both the Claude Desktop app and the Claude mobile app.

## 2. How It Works

Instead of starting a new session for each task, you have a single persistent thread with Claude. This thread does not reset - Claude retains context from previous tasks, so you can pick up where you left off.

Message Claude from your phone on the way to work, then follow up from your desktop when you sit down. Same conversation, same context, wherever you reach it.

When you assign a task, Claude figures out what kind of work is needed and spins up the right session:
- Development tasks run in **Claude Code**
- Knowledge work runs in **Cowork**

These sessions appear in their respective sidebars. You can click into any session for details, or wait for the result in the thread.

Claude messages you the outcome - a spreadsheet, a memo, a comparison table, a pull request - rather than showing you every step of the process. You get a push notification on your phone when a task is done or when Claude needs your go-ahead.

## 3. Requirements

- Latest version of the **Claude Desktop app** installed and running on your computer (macOS or Windows x64). Your computer must be awake and the app must be open for Claude to work on tasks
- Latest version of the **Claude mobile app** installed on your phone
- A **Pro or Max plan**
- An active internet connection on both devices

## 4. Getting Started

1. Download or update Claude Desktop
2. Download or update Claude for iOS/Android
3. Open Cowork on either your phone or your desktop
4. Click **"Dispatch"** on the left side panel
5. You will land on a page describing the functionality. Click **"Get started"**
6. On the next screen, you can give Claude access to your files and keep your computer awake by toggling those on
7. Click **"Finish setup"**
8. Start messaging Claude within the "Dispatch" section

After completing these steps, your continuous conversation with Claude syncs across both surfaces automatically.

## 5. What You Can Do

### Computer Use

Claude can use the apps on your computer to complete tasks you assign through Dispatch. If you ask Claude to update a spreadsheet in Excel, navigate an internal dashboard, or run your dev tools, Claude can work directly with those apps on your desktop.

### Memory

Claude remembers what you have worked on and learns how you work. Context carries across sessions, so you do not have to re-explain your preferences, your projects, or how you like things done. You control what Claude remembers. You can view, edit, and delete your memory at any time.

### Task Routing

Claude automatically determines the type of work needed:

| Task Type | Runs In | Output |
|---|---|---|
| Development work | Claude Code | Pull requests, code changes |
| Knowledge work | Cowork | Spreadsheets, memos, reports |
| App interaction | Computer Use | Direct app manipulation |

## 6. Current Limitations

This is a research preview with the following limitations:

- **Desktop must be active** - Claude works on your desktop computer. If your computer is asleep or the Claude Desktop app is closed, Claude cannot work on tasks
- **Computer use runs outside the virtual machine** - When Claude uses your apps through computer use, it operates outside the Cowork sandbox
- **One continuous thread** - There is no way to start a new thread or manage multiple threads. All messages live in a single conversation
