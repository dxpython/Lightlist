// pages/EditTask.ets
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
struct EditTaskPage {
  @State taskId: number = 0
  @State title: string = ''
  @State content: string = ''
  @State reminderTime: string = ''
  @State completed: boolean = false
  @State createdAt: string = ''
  @State showDatePicker: boolean = false
  @State showTimePicker: boolean = false
  @State showDeleteDialog: boolean = false
  @State selectedDate: Date = new Date()
  @State selectedTime: Date = new Date()
  @State isLoading: boolean = false
  @State taskNotFound: boolean = false

  // 页面显示时
  aboutToAppear() {
    this.loadTaskData()
  }

  // 加载任务数据
  async loadTaskData() {
    try {
      const params = router.getParams() as { taskId: number }
      if (!params || !params.taskId) {
        this.taskNotFound = true
        return
      }

      this.taskId = params.taskId

      // 从本地存储读取任务数据
      const context = getContext(this)
      const dataPreferences = await preferences.getPreferences(context, 'todoApp')
      const tasksData = await dataPreferences.get('tasks', '[]')

      let tasks: TaskItem[] = []
      if (typeof tasksData === 'string') {
        tasks = JSON.parse(tasksData)
      }

      // 查找对应的任务
      const task = tasks.find(t => t.id === this.taskId)
      if (!task) {
        this.taskNotFound = true
        return
      }

      // 填充表单数据
      this.title = task.title
      this.content = task.content
      this.completed = task.completed
      this.createdAt = task.createdAt
      this.reminderTime = task.reminderTime || ''

      // 设置日期时间选择器的初始值
      if (this.reminderTime) {
        const reminderDate = new Date(this.reminderTime)
        this.selectedDate = reminderDate
        this.selectedTime = reminderDate
      }
    } catch (error) {
      console.error('加载任务数据失败:', error)
      this.taskNotFound = true
    }
  }

  // 格式化日期时间显示
  formatDateTime(date: Date): string {
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')

    return `${year}-${month}-${day} ${hours}:${minutes}`
  }

  // 设置提醒时间
  setReminderTime() {
    const combinedDateTime = new Date(
      this.selectedDate.getFullYear(),
      this.selectedDate.getMonth(),
      this.selectedDate.getDate(),
      this.selectedTime.getHours(),
      this.selectedTime.getMinutes()
    )
    this.reminderTime = this.formatDateTime(combinedDateTime)
  }

  // 清除提醒时间
  clearReminderTime() {
    this.reminderTime = ''
  }

  // 保存任务修改
  async saveTask() {
    // 验证输入
    if (!this.title.trim()) {
      return
    }

    this.isLoading = true

    try {
      // 从本地存储读取现有任务
      const context = getContext(this)
      const dataPreferences = await preferences.getPreferences(context, 'todoApp')
      const tasksData = await dataPreferences.get('tasks', '[]')

      let tasks: TaskItem[] = []
      if (typeof tasksData === 'string') {
        tasks = JSON.parse(tasksData)
      }

      // 查找并更新任务
      const taskIndex = tasks.findIndex(t => t.id === this.taskId)
      if (taskIndex !== -1) {
        tasks[taskIndex] = {
          ...tasks[taskIndex],
          title: this.title.trim(),
          content: this.content.trim(),
          reminderTime: this.reminderTime || undefined
        }

        // 保存到本地存储
        await dataPreferences.put('tasks', JSON.stringify(tasks))
        await dataPreferences.flush()

        // 返回首页
        router.back()
      }
    } catch (error) {
      console.error('保存任务失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  // 删除任务
  async deleteTask() {
    this.isLoading = true

    try {
      // 从本地存储读取现有任务
      const context = getContext(this)
      const dataPreferences = await preferences.getPreferences(context, 'todoApp')
      const tasksData = await dataPreferences.get('tasks', '[]')

      let tasks: TaskItem[] = []
      if (typeof tasksData === 'string') {
        tasks = JSON.parse(tasksData)
      }

      // 删除任务
      tasks = tasks.filter(t => t.id !== this.taskId)

      // 保存到本地存储
      await dataPreferences.put('tasks', JSON.stringify(tasks))
      await dataPreferences.flush()

      // 返回首页
      router.back()
    } catch (error) {
      console.error('删除任务失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  // 取消操作
  cancelEdit() {
    router.back()
  }

  // 格式化创建时间显示
  formatCreatedTime(): string {
    if (!this.createdAt) return ''

    const date = new Date(this.createdAt)
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const taskDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())

    const timeStr = `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`

    if (taskDate.getTime() === today.getTime()) {
      return `今天 ${timeStr} 创建`
    } else if (taskDate.getTime() === today.getTime() - 24 * 60 * 60 * 1000) {
      return `昨天 ${timeStr} 创建`
    } else {
      return `${date.getMonth() + 1}/${date.getDate()} ${timeStr} 创建`
    }
  }

  build() {
    Stack() {
      if (this.taskNotFound) {
        // 任务未找到页面
        Column() {
          Text('😕')
            .fontSize(48)
            .margin({ bottom: 16 })

          Text('任务不存在')
            .fontSize(18)
            .fontColor('#6b7280')
            .margin({ bottom: 8 })

          Text('该任务可能已被删除')
            .fontSize(14)
            .fontColor('#9ca3af')
            .margin({ bottom: 24 })

          Button('返回')
            .fontSize(16)
            .fontColor('#ffffff')
            .backgroundColor('#2563eb')
            .width(120)
            .onClick(() => {
              router.back()
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#f9fafb')
      } else {
        // 主界面
        Column() {
          // 顶部导航栏
          Row() {
            Text('取消')
              .fontSize(16)
              .fontColor('#2563eb')
              .onClick(() => {
                this.cancelEdit()
              })

            Blank()

            Text('编辑任务')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1f2937')

            Blank()

            Text(this.isLoading ? '保存中...' : '保存')
              .fontSize(16)
              .fontColor(this.title.trim() ? '#2563eb' : '#9ca3af')
              .onClick(() => {
                if (!this.isLoading && this.title.trim()) {
                  this.saveTask()
                }
              })
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#ffffff')
          .border({ width: { bottom: 1 }, color: '#e5e7eb' })

          // 主要内容区域
          Scroll() {
            Column() {
              // 任务状态和创建时间
              Row() {
                Row() {
                  Text(this.completed ? '✅' : '⏳')
                    .fontSize(16)
                    .margin({ right: 8 })

                  Text(this.completed ? '已完成' : '进行中')
                    .fontSize(14)
                    .fontColor(this.completed ? '#16a34a' : '#ea580c')
                    .fontWeight(FontWeight.Medium)
                }

                Blank()

                Text(this.formatCreatedTime())
                  .fontSize(12)
                  .fontColor('#9ca3af')
              }
              .width('100%')
              .margin({ bottom: 24 })

              // 任务标题输入
              Column() {
                Text('任务标题 *')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#374151')
                  .alignSelf(ItemAlign.Start)
                  .margin({ bottom: 8 })

                TextInput({ text: this.title, placeholder: '请输入任务标题' })
                  .fontSize(16)
                  .fontColor('#1f2937')
                  .backgroundColor('#f9fafb')
                  .border({ width: 1, color: '#d1d5db', radius: 8 })
                  .height(48)
                  .onChange((value: string) => {
                    this.title = value
                  })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 24 })

              // 任务内容输入
              Column() {
                Text('任务内容')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#374151')
                  .alignSelf(ItemAlign.Start)
                  .margin({ bottom: 8 })

                TextArea({ text: this.content, placeholder: '请输入任务的详细描述...' })
                  .fontSize(16)
                  .fontColor('#1f2937')
                  .backgroundColor('#f9fafb')
                  .border({ width: 1, color: '#d1d5db', radius: 8 })
                  .height(120)
                  .onChange((value: string) => {
                    this.content = value
                  })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 24 })

              // 提醒时间设置
              Column() {
                Row() {
                  Text('提醒时间')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#374151')

                  Blank()

                  if (this.reminderTime) {
                    Text('清除')
                      .fontSize(14)
                      .fontColor('#ef4444')
                      .onClick(() => {
                        this.clearReminderTime()
                      })
                  }
                }
                .width('100%')
                .margin({ bottom: 12 })

                // 提醒时间显示/设置区域
                if (this.reminderTime) {
                  // 已设置提醒时间
                  Row() {
                    Text('📅')
                      .fontSize(20)
                      .margin({ right: 12 })

                    Column() {
                      Text(this.reminderTime)
                        .fontSize(16)
                        .fontColor('#1f2937')
                        .fontWeight(FontWeight.Medium)
                      Text('点击修改提醒时间')
                        .fontSize(12)
                        .fontColor('#6b7280')
                        .margin({ top: 2 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    Text('>')
                      .fontSize(16)
                      .fontColor('#9ca3af')
                  }
                  .width('100%')
                  .padding(16)
                  .backgroundColor('#f0f9ff')
                  .borderRadius(8)
                  .border({ width: 1, color: '#bae6fd' })
                  .onClick(() => {
                    this.showDatePicker = true
                  })
                } else {
                  // 未设置提醒时间
                  Row() {
                    Text('⏰')
                      .fontSize(18)
                      .margin({ right: 12 })

                    Text('设置提醒时间')
                      .fontSize(16)
                      .fontColor('#6b7280')
                      .layoutWeight(1)

                    Text('+')
                      .fontSize(20)
                      .fontColor('#2563eb')
                  }
                  .width('100%')
                  .height(56)
                  .padding({ left: 16, right: 16 })
                  .backgroundColor('#ffffff')
                  .borderRadius(8)
                  .border({ width: 1, color: '#d1d5db', style: BorderStyle.Dashed })
                  .onClick(() => {
                    this.showDatePicker = true
                  })
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 32 })

              // 删除任务按钮
              Row() {
                Text('🗑')
                  .fontSize(18)
                  .margin({ right: 8 })

                Text('删除任务')
                  .fontSize(16)
                  .fontColor('#ef4444')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })
              .backgroundColor('#fef2f2')
              .borderRadius(8)
              .border({ width: 1, color: '#fecaca' })
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.showDeleteDialog = true
              })
              .margin({ bottom: 16 })

              // 提示信息
              Text('* 任务标题为必填项')
                .fontSize(12)
                .fontColor('#9ca3af')
                .alignSelf(ItemAlign.Start)
            }
            .width('100%')
            .padding(16)
          }
          .layoutWeight(1)
          .backgroundColor('#ffffff')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#f9fafb')
      }

      // 删除确认对话框
      if (this.showDeleteDialog) {
        Column() {
          Column() {
            // 遮罩层
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#00000080')
          .onClick(() => {
            this.showDeleteDialog = false
          })

          Column() {
            Text('确认删除')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 16 })

            Text('删除后无法恢复，确定要删除这个任务吗？')
              .fontSize(14)
              .fontColor('#6b7280')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 24 })

            Row() {
              Button('取消')
                .fontSize(16)
                .fontColor('#6b7280')
                .backgroundColor('#f3f4f6')
                .width('45%')
                .onClick(() => {
                  this.showDeleteDialog = false
                })

              Button(this.isLoading ? '删除中...' : '删除')
                .fontSize(16)
                .fontColor('#ffffff')
                .backgroundColor('#ef4444')
                .width('45%')
                .onClick(() => {
                  if (!this.isLoading) {
                    this.showDeleteDialog = false
                    this.deleteTask()
                  }
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width('85%')
          .padding(24)
          .backgroundColor('#ffffff')
          .borderRadius(12)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }

      // 日期选择器
      if (this.showDatePicker) {
        Column() {
          Column() {
            // 遮罩层
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#00000080')
          .onClick(() => {
            this.showDatePicker = false
          })

          Column() {
            Text('选择日期')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 16 })

            DatePicker({
              start: new Date(),
              end: new Date(2030, 11, 31),
              selected: this.selectedDate
            })
              .onChange((value: DatePickerResult) => {
                this.selectedDate = new Date(value.year, value.month, value.day)
              })

            Row() {
              Button('取消')
                .fontSize(16)
                .fontColor('#6b7280')
                .backgroundColor('#f3f4f6')
                .width('45%')
                .onClick(() => {
                  this.showDatePicker = false
                })

              Button('确定')
                .fontSize(16)
                .fontColor('#ffffff')
                .backgroundColor('#2563eb')
                .width('45%')
                .onClick(() => {
                  this.showDatePicker = false
                  this.showTimePicker = true
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 24 })
          }
          .width('90%')
          .padding(24)
          .backgroundColor('#ffffff')
          .borderRadius(12)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }

      // 时间选择器
      if (this.showTimePicker) {
        Column() {
          Column() {
            // 遮罩层
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#00000080')
          .onClick(() => {
            this.showTimePicker = false
          })

          Column() {
            Text('选择时间')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 16 })

            TimePicker({
              selected: this.selectedTime
            })
              .onChange((value: TimePickerResult) => {
                const newTime = new Date()
                newTime.setHours(value.hour, value.minute)
                this.selectedTime = newTime
              })

            Row() {
              Button('取消')
                .fontSize(16)
                .fontColor('#6b7280')
                .backgroundColor('#f3f4f6')
                .width('45%')
                .onClick(() => {
                  this.showTimePicker = false
                })

              Button('确定')
                .fontSize(16)
                .fontColor('#ffffff')
                .backgroundColor('#2563eb')
                .width('45%')
                .onClick(() => {
                  this.showTimePicker = false
                  this.setReminderTime()
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 24 })
          }
          .width('90%')
          .padding(24)
          .backgroundColor('#ffffff')
          .borderRadius(12)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}