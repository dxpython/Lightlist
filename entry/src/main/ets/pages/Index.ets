/**
 * Desined By: Charles Dong
 * Date: 2025/5/26
 * 鸿蒙原生应用，遥遥领先
 * */
// pages/Index.ets

import router from '@ohos.router'
import preferences from '@ohos.data.preferences'

// 任务数据接口
interface TaskItem {
  id: number
  title: string
  content: string
  completed: boolean
  createdAt: string
  reminderTime?: string
}

@Entry
@Component
struct HomePage {
  @State tasks: TaskItem[] = []
  @State totalTasks: number = 0
  @State completedTasks: number = 0
  @State reminderTimer: number = -1

  // 生命周期：页面显示时
  aboutToAppear() {
    this.loadTasksFromStorage()
    this.startReminderCheck()
  }

  // 页面消失时清理定时器
  aboutToDisappear() {
    if (this.reminderTimer !== -1) {
      clearInterval(this.reminderTimer)
    }
  }

  // 从本地存储加载任务数据
  async loadTasksFromStorage() {
    try {
      const context = getContext(this)
      const dataPreferences = await preferences.getPreferences(context, 'todoApp')
      const tasksData = await dataPreferences.get('tasks', '[]')

      if (typeof tasksData === 'string') {
        this.tasks = JSON.parse(tasksData)
      }

      // 如果没有数据，添加示例数据
      if (this.tasks.length === 0) {
        this.tasks = [
          {
            id: 1,
            title: '完成项目报告',
            content: '需要整理本月的工作总结和下月计划',
            completed: false,
            createdAt: '2025-05-25 09:30',
            reminderTime: '2025-05-26 14:00'
          },
          {
            id: 2,
            title: '购买生活用品',
            content: '牙膏、洗发水、面包、牛奶',
            completed: true,
            createdAt: '2025-05-24 18:20'
          },
          {
            id: 3,
            title: '锻炼身体',
            content: '跑步30分钟',
            completed: false,
            createdAt: '2025-05-25 07:00',
            reminderTime: '2025-05-25 19:00'
          }
        ]
        await this.saveTasksToStorage()
      }

      this.updateStatistics()
    } catch (error) {
      console.error('加载任务数据失败:', error)
    }
  }

  // 保存任务数据到本地存储
  async saveTasksToStorage() {
    try {
      const context = getContext(this)
      const dataPreferences = await preferences.getPreferences(context, 'todoApp')
      await dataPreferences.put('tasks', JSON.stringify(this.tasks))
      await dataPreferences.flush()
    } catch (error) {
      console.error('保存任务数据失败:', error)
    }
  }

  // 更新统计信息
  updateStatistics() {
    this.totalTasks = this.tasks.length
    this.completedTasks = this.tasks.filter(task => task.completed).length
  }

  // 切换任务完成状态
  async toggleTaskCompletion(taskId: number) {
    const taskIndex = this.tasks.findIndex(task => task.id === taskId)
    if (taskIndex !== -1) {
      this.tasks[taskIndex].completed = !this.tasks[taskIndex].completed
      await this.saveTasksToStorage()
      this.updateStatistics()
    }
  }

  // 删除任务
  async deleteTask(taskId: number) {
    this.tasks = this.tasks.filter(task => task.id !== taskId)
    await this.saveTasksToStorage()
    this.updateStatistics()
  }

  // 检查提醒是否激活（时间已到或即将到）
  isReminderActive(reminderTime: string): boolean {
    if (!reminderTime) return false

    const now = new Date()
    const reminderDate = new Date(reminderTime)
    const timeDiff = reminderDate.getTime() - now.getTime()

    // 如果时间已过或在5分钟内
    return timeDiff <= 5 * 60 * 1000
  }

  // 启动提醒检查
  startReminderCheck() {
    // 每分钟检查一次提醒
    this.reminderTimer = setInterval(() => {
      this.checkReminders()
    }, 60000) // 60秒检查一次

    // 立即检查一次
    this.checkReminders()
  }

  // 检查所有任务的提醒
  checkReminders() {
    const now = new Date()

    this.tasks.forEach(task => {
      if (!task.completed && task.reminderTime) {
        const reminderDate = new Date(task.reminderTime)
        const timeDiff = reminderDate.getTime() - now.getTime()

        // 如果提醒时间到了（误差在1分钟内）
        if (Math.abs(timeDiff) <= 60000) {
          this.showReminder(task)
        }
      }
    })
  }

  // 显示提醒（简单的控制台提醒，实际应用中可以使用通知）
  showReminder(task: TaskItem) {
    console.log(`⏰ 提醒：${task.title}`)
    console.log(`📝 内容：${task.content}`)

    // 这里可以添加更复杂的提醒逻辑
    // 比如系统通知、弹窗等
    // 由于鸿蒙通知需要权限配置，这里先用日志提醒
  }

  // 获取排序后的任务列表（未完成优先）
  getSortedTasks(): TaskItem[] {
    return this.tasks.sort((a, b) => {
      if (a.completed === b.completed) {
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      }
      return Number(a.completed) - Number(b.completed)
    })
  }

  // 格式化时间显示
  formatTime(timeString: string): string {
    if (!timeString) return ''

    const date = new Date(timeString)
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const taskDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())

    const timeStr = `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`

    if (taskDate.getTime() === today.getTime()) {
      return `今天 ${timeStr}`
    } else if (taskDate.getTime() === today.getTime() - 24 * 60 * 60 * 1000) {
      return `昨天 ${timeStr}`
    } else {
      return `${date.getMonth() + 1}/${date.getDate()} ${timeStr}`
    }
  }

  // 跳转到添加任务页面
  navigateToAddTask() {
    router.pushUrl({
      url: 'pages/AddTask'
    })
  }

  // 跳转到编辑任务页面
  navigateToEditTask(taskId: number) {
    router.pushUrl({
      url: 'pages/EditTask',
      params: { taskId: taskId }
    })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部统计信息区域 - 精美设计
        Column() {
          // 渐变背景头部
          Column() {
            Row() {
              Column() {
                Text('✨ 我的待办')
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#ffffff')

                Text('让每一天都充满成就感')
                  .fontSize(14)
                  .fontColor('#e0f2fe')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              // 个人头像区域
              Row() {
                Text('👤')
                  .fontSize(24)
              }
              .width(48)
              .height(48)
              .borderRadius(24)
              .backgroundColor('#ffffff20')
              .justifyContent(FlexAlign.Center)
            }
            .width('100%')
            .margin({ bottom: 24 })
            // 统计卡片区域
            Row() {
              // 总任务卡片
              Column() {
                Row() {
                  Text('📋')
                    .fontSize(20)
                    .margin({ right: 8 })

                  Column() {
                    Text(this.totalTasks.toString())
                      .fontSize(24)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#ffffff')
                    Text('总任务')
                      .fontSize(12)
                      .fontColor('#e0f2fe')
                  }
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
              }
              .width('30%')
              .height(70)
              .padding(12)
              .backgroundColor('#ffffff20')
              .borderRadius(12)

              // 已完成卡片
              Column() {
                Row() {
                  Text('✅')
                    .fontSize(20)
                    .margin({ right: 8 })

                  Column() {
                    Text(this.completedTasks.toString())
                      .fontSize(24)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#ffffff')
                    Text('已完成')
                      .fontSize(12)
                      .fontColor('#e0f2fe')
                  }
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
              }
              .width('30%')
              .height(70)
              .padding(12)
              .backgroundColor('#ffffff20')
              .borderRadius(12)

              // 完成率卡片
              Column() {
                Row() {
                  Text('🎯')
                    .fontSize(20)
                    .margin({ right: 8 })

                  Column() {
                    Text(`${this.totalTasks > 0 ? Math.round((this.completedTasks / this.totalTasks) * 100) : 0}%`)
                      .fontSize(24)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#ffffff')
                    Text('完成率')
                      .fontSize(12)
                      .fontColor('#e0f2fe')
                  }
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
              }
              .width('30%')
              .height(70)
              .padding(12)
              .backgroundColor('#ffffff20')
              .borderRadius(12)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width('100%')
          .padding(20)
          .linearGradient({
            angle: 135,
            colors: [['#667eea', 0.0], ['#764ba2', 1.0]]
          })
          .borderRadius({ bottomLeft: 24, bottomRight: 24 })
        }

        // 任务列表区域
        if (this.tasks.length === 0) {
          // 精美的空状态
          Column() {
            Text('🎉')
              .fontSize(64)
              .margin({ bottom: 16 })

            Text('太棒了！')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4f46e5')
              .margin({ bottom: 8 })

            Text('暂时没有待办任务')
              .fontSize(16)
              .fontColor('#6b7280')
              .margin({ bottom: 4 })

            Text('点击右下角的按钮添加第一个任务吧')
              .fontSize(14)
              .fontColor('#9ca3af')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          // 精美的任务列表
          Column() {
            // 列表标题
            Row() {
              Text('📝 任务清单')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1f2937')

              Blank()

              Text(`${this.totalTasks - this.completedTasks} 项待完成`)
                .fontSize(14)
                .fontColor('#6b7280')
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .backgroundColor('#f3f4f6')
                .borderRadius(12)
            }
            .width('100%')
            .margin({ bottom: 16 })

            List({ space: 16 }) {
              ForEach(this.getSortedTasks(), (task: TaskItem) => {
                ListItem() {
                  Row() {
                    // 完成状态复选框 - 精美样式
                    Row() {
                      if (task.completed) {
                        Text('✓')
                          .fontSize(16)
                          .fontColor('#ffffff')
                          .fontWeight(FontWeight.Bold)
                      }
                    }
                    .width(28)
                    .height(28)
                    .borderRadius(14)
                    .backgroundColor(task.completed ? '#10b981' : '#ffffff')
                    .border({
                      width: 2,
                      color: task.completed ? '#10b981' : '#e5e7eb'
                    })
                    .justifyContent(FlexAlign.Center)
                    .shadow({
                      radius: task.completed ? 8 : 4,
                      color: task.completed ? '#10b98120' : '#00000010',
                      offsetX: 0,
                      offsetY: 2
                    })
                    .onClick(() => {
                      this.toggleTaskCompletion(task.id)
                    })

                    // 任务内容区域
                    Column() {
                      Text(task.title)
                        .fontSize(18)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(task.completed ? '#9ca3af' : '#1f2937')
                        .decoration({
                          type: task.completed ? TextDecorationType.LineThrough : TextDecorationType.None
                        })
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      if (task.content) {
                        Text(task.content)
                          .fontSize(15)
                          .fontColor(task.completed ? '#9ca3af' : '#6b7280')
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .margin({ top: 4 })
                      }

                      // 时间信息行
                      Row() {
                        // 创建时间
                        Row() {
                          Text('🕐')
                            .fontSize(12)
                          Text(`${this.formatTime(task.createdAt)}`)
                            .fontSize(12)
                            .fontColor('#9ca3af')
                            .margin({ left: 4 })
                        }

                        if (task.reminderTime) {
                          Row() {
                            Text('⏰')
                              .fontSize(12)
                            Text(`${this.formatTime(task.reminderTime)}`)
                              .fontSize(12)
                              .fontColor(this.isReminderActive(task.reminderTime) ? '#ef4444' : '#9ca3af')
                              .margin({ left: 4 })
                          }
                          .margin({ left: 16 })
                        }
                      }
                      .margin({ top: 8 })
                    }
                    .layoutWeight(1)
                    .margin({ left: 16, right: 16 })
                    .alignItems(HorizontalAlign.Start)
                    .onClick(() => {
                      this.navigateToEditTask(task.id)
                    })

                    // 删除按钮 - 精美样式
                    Row() {
                      Text('🗑')
                        .fontSize(16)
                    }
                    .width(36)
                    .height(36)
                    .borderRadius(18)
                    .backgroundColor('#fef2f2')
                    .border({ width: 1, color: '#fecaca' })
                    .justifyContent(FlexAlign.Center)
                    .onClick(() => {
                      this.deleteTask(task.id)
                    })
                  }
                  .width('100%')
                  .padding(20)
                  .backgroundColor(task.completed ? '#f8fafc' : '#ffffff')
                  .borderRadius(16)
                  .border({
                    width: 1,
                    color: task.completed ? '#e2e8f0' : '#f1f5f9'
                  })
                  .shadow({
                    radius: 8,
                    color: '#00000008',
                    offsetX: 0,
                    offsetY: 4
                  })
                }
                .swipeAction({ end: this.deleteButton(task.id) })
              })
            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20, top: 20, bottom: 100 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f8fafc')

      // 精美的浮动添加按钮
      Row() {
        Text('+')
          .fontSize(28)
          .fontColor('#ffffff')
          .fontWeight(FontWeight.Bold)
      }
      .width(64)
      .height(64)
      .borderRadius(32)
      .linearGradient({
        angle: 135,
        colors: [['#667eea', 0.0], ['#764ba2', 1.0]]
      })
      .justifyContent(FlexAlign.Center)
      .margin({ right: 20, bottom: 20 })
      .shadow({
        radius: 16,
        color: '#667eea40',
        offsetX: 0,
        offsetY: 8
      })
      .onClick(() => {
        this.navigateToAddTask()
      })
    }
    .width('100%')
    .height('100%')
  }

  // 滑动删除按钮
  @Builder deleteButton(taskId: number) {
    Row() {
      Text('删除')
        .fontSize(14)
        .fontColor('#ffffff')
        .fontWeight(FontWeight.Medium)
    }
    .width(80)
    .height('100%')
    .backgroundColor('#ef4444')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.deleteTask(taskId)
    })
  }
}