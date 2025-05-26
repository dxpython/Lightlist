// pages/AddTask.ets
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
struct AddTaskPage {
  @State title: string = ''
  @State content: string = ''
  @State reminderTime: string = ''
  @State showDatePicker: boolean = false
  @State showTimePicker: boolean = false
  @State selectedDate: Date = new Date()
  @State selectedHour: number = 9
  @State selectedMinute: number = 0
  @State selectedAmPm: string = 'AM'
  @State isLoading: boolean = false

  // 生成新的任务ID
  generateNewId(): number {
    return Date.now()
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
    // 转换12小时制到24小时制
    let hour24 = this.selectedHour
    if (this.selectedAmPm === 'PM' && this.selectedHour !== 12) {
      hour24 = this.selectedHour + 12
    } else if (this.selectedAmPm === 'AM' && this.selectedHour === 12) {
      hour24 = 0
    }

    const combinedDateTime = new Date(
      this.selectedDate.getFullYear(),
      this.selectedDate.getMonth(),
      this.selectedDate.getDate(),
      hour24,
      this.selectedMinute
    )
    this.reminderTime = this.formatDateTime(combinedDateTime)
  }

  // 清除提醒时间
  clearReminderTime() {
    this.reminderTime = ''
  }

  // 获取当前时间显示文本
  getCurrentTimeDisplay(): string {
    // 转换为24小时制显示
    let hour24 = this.selectedHour
    if (this.selectedAmPm === 'PM' && this.selectedHour !== 12) {
      hour24 = this.selectedHour + 12
    } else if (this.selectedAmPm === 'AM' && this.selectedHour === 12) {
      hour24 = 0
    }
    return `${hour24.toString().padStart(2, '0')}:${this.selectedMinute.toString().padStart(2, '0')}`
  }

  // 保存任务
  async saveTask() {
    // 验证输入
    if (!this.title.trim()) {
      console.log('任务标题为空，无法保存')
      return
    }

    this.isLoading = true
    console.log('开始保存任务...')

    try {
      // 创建新任务
      const newTask: TaskItem = {
        id: this.generateNewId(),
        title: this.title.trim(),
        content: this.content.trim(),
        completed: false,
        createdAt: this.formatDateTime(new Date()),
        reminderTime: this.reminderTime || undefined
      }

      console.log('新任务数据:', newTask)

      // 从本地存储读取现有任务
      const context = getContext(this)
      const dataPreferences = await preferences.getPreferences(context, 'todoApp')
      const tasksData = await dataPreferences.get('tasks', '[]')

      let tasks: TaskItem[] = []
      if (typeof tasksData === 'string') {
        tasks = JSON.parse(tasksData)
      }

      // 添加新任务
      tasks.push(newTask)
      console.log('任务列表更新后:', tasks.length, '个任务')

      // 保存到本地存储
      await dataPreferences.put('tasks', JSON.stringify(tasks))
      await dataPreferences.flush()
      console.log('任务保存成功，准备返回首页')

      // 短暂延时后跳转
      setTimeout(() => {
        // 返回首页 - 尝试多种方法
        try {
          // 方法1：使用 replaceUrl
          router.replaceUrl({
            url: 'pages/Index'
          }).then(() => {
            console.log('使用 replaceUrl 跳转成功')
          }).catch((error) => {
            console.log('replaceUrl 失败:', error)
            // 方法2：使用 back
            router.back()
            console.log('fallback 到 router.back()')
          })
        } catch (error) {
          console.log('跳转异常:', error)
          router.back()
        }
      }, 100)
    } catch (error) {
      console.error('保存任务失败:', error)
    } finally {
      this.isLoading = false
    }
  }

  // 取消操作
  cancelAdd() {
    router.back()
  }

  build() {
    Stack() {
      // 主界面
      Column() {
        // 顶部导航栏
        Row() {
          Text('取消')
            .fontSize(16)
            .fontColor('#2563eb')
            .onClick(() => {
              this.cancelAdd()
            })

          Blank()

          Text('添加任务')
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
        Column() {
          // 任务标题输入
          Column() {
            Text('任务标题 *')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#374151')
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 8 })

            TextInput({ placeholder: '请输入任务标题' })
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

            TextArea({ placeholder: '请输入任务的详细描述...' })
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
              Button() {
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
                .justifyContent(FlexAlign.Start)
              }
              .width('100%')
              .height(70)
              .padding(16)
              .backgroundColor('#f0f9ff')
              .borderRadius(8)
              .border({ width: 1, color: '#bae6fd' })
              .onClick(() => {
                this.showDatePicker = true
              })
            } else {
              // 未设置提醒时间
              Button() {
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
                .justifyContent(FlexAlign.Start)
              }
              .width('100%')
              .height(56)
              .backgroundColor('#ffffff')
              .borderRadius(8)
              .border({ width: 1, color: '#d1d5db', style: BorderStyle.Dashed })
              .onClick(() => {
                console.log('点击设置提醒时间')
                this.showDatePicker = true
              })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 32 })

          // 提示信息
          Text('* 任务标题为必填项')
            .fontSize(12)
            .fontColor('#9ca3af')
            .alignSelf(ItemAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .padding(16)
        .backgroundColor('#ffffff')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f9fafb')

      // 日期选择器
      if (this.showDatePicker) {
        Column() {
          // 遮罩层
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#00000080')
            .onClick(() => {
              console.log('点击遮罩层，关闭日期选择器')
              this.showDatePicker = false
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 日期选择器弹窗
        Column() {
          Text('选择日期')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1f2937')
            .margin({ bottom: 16 })

          DatePicker({
            start: new Date(),
            end: new Date(2030, 11, 31),
            selected: this.selectedDate
          })
            .onChange((value: DatePickerResult) => {
              console.log('选择日期:', value.year, value.month, value.day)
              this.selectedDate = new Date(value.year, value.month, value.day)
            })

          Row() {
            Button('取消')
              .fontSize(16)
              .fontColor('#6b7280')
              .backgroundColor('#f3f4f6')
              .width('40%')
              .onClick(() => {
                console.log('取消选择日期')
                this.showDatePicker = false
              })

            Button('确定')
              .fontSize(16)
              .fontColor('#ffffff')
              .backgroundColor('#2563eb')
              .width('40%')
              .onClick(() => {
                console.log('确定选择日期，打开时间选择器')
                this.showDatePicker = false
                this.showTimePicker = true
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
          .margin({ top: 24 })
        }
        .width('80%')
        .padding(20)
        .backgroundColor('#ffffff')
        .borderRadius(12)
        .position({ x: '10%', y: '35%' })
      }

      // 时间选择器
      if (this.showTimePicker) {
        Column() {
          // 遮罩层
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#00000080')
            .onClick(() => {
              console.log('点击遮罩层，关闭时间选择器')
              this.showTimePicker = false
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 时间选择器弹窗
        Column() {
          Text('选择时间')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1f2937')
            .margin({ bottom: 16 })

          // 自定义时间选择器
          Row() {
            // 小时选择
            Column() {
              Text('小时')
                .fontSize(14)
                .fontColor('#6b7280')
                .margin({ bottom: 8 })

              List() {
                ForEach([1,2,3,4,5,6,7,8,9,10,11,12], (hour: number) => {
                  ListItem() {
                    Text(hour.toString())
                      .fontSize(16)
                      .fontColor(this.selectedHour === hour ? '#ffffff' : '#1f2937')
                      .fontWeight(this.selectedHour === hour ? FontWeight.Bold : FontWeight.Normal)
                      .width(40)
                      .height(32)
                      .textAlign(TextAlign.Center)
                      .backgroundColor(this.selectedHour === hour ? '#2563eb' : '#f9fafb')
                      .borderRadius(6)
                      .onClick(() => {
                        this.selectedHour = hour
                      })
                  }
                  .margin({ bottom: 4 })
                })
              }
              .height(150)
              .width('100%')
            }
            .width('30%')

            // 分钟选择
            Column() {
              Text('分钟')
                .fontSize(14)
                .fontColor('#6b7280')
                .margin({ bottom: 8 })

              List() {
                ForEach(Array.from({length: 60}, (_, i) => i), (minute: number) => {
                  ListItem() {
                    Text(minute.toString().padStart(2, '0'))
                      .fontSize(16)
                      .fontColor(this.selectedMinute === minute ? '#ffffff' : '#1f2937')
                      .fontWeight(this.selectedMinute === minute ? FontWeight.Bold : FontWeight.Normal)
                      .width(40)
                      .height(32)
                      .textAlign(TextAlign.Center)
                      .backgroundColor(this.selectedMinute === minute ? '#2563eb' : '#f9fafb')
                      .borderRadius(6)
                      .onClick(() => {
                        this.selectedMinute = minute
                      })
                  }
                  .margin({ bottom: 4 })
                })
              }
              .height(150)
              .width('100%')
            }
            .width('30%')

            // AM/PM 选择
            Column() {
              Text('上/下午')
                .fontSize(14)
                .fontColor('#6b7280')
                .margin({ bottom: 8 })

              Column() {
                ForEach(['AM', 'PM'], (period: string) => {
                  Text(period === 'AM' ? '上午' : '下午')
                    .fontSize(16)
                    .fontColor(this.selectedAmPm === period ? '#ffffff' : '#1f2937')
                    .fontWeight(this.selectedAmPm === period ? FontWeight.Bold : FontWeight.Normal)
                    .width(50)
                    .height(32)
                    .textAlign(TextAlign.Center)
                    .backgroundColor(this.selectedAmPm === period ? '#2563eb' : '#f9fafb')
                    .borderRadius(6)
                    .margin({ bottom: 4 })
                    .onClick(() => {
                      this.selectedAmPm = period
                    })
                })
              }
            }
            .width('35%')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
          .margin({ bottom: 20 })

          // 当前选择显示
          Text(this.getCurrentTimeDisplay())
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#2563eb')
            .margin({ bottom: 20 })

          Row() {
            Button('取消')
              .fontSize(16)
              .fontColor('#6b7280')
              .backgroundColor('#f3f4f6')
              .width('40%')
              .onClick(() => {
                console.log('取消选择时间')
                this.showTimePicker = false
              })

            Button('确定')
              .fontSize(16)
              .fontColor('#ffffff')
              .backgroundColor('#2563eb')
              .width('40%')
              .onClick(() => {
                console.log('确定选择时间，设置提醒')
                this.showTimePicker = false
                this.setReminderTime()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
          .margin({ top: 24 })
        }
        .width('85%')
        .padding(20)
        .backgroundColor('#ffffff')
        .borderRadius(12)
        .position({ x: '7.5%', y: '25%' })
      }
    }
    .width('100%')
    .height('100%')
  }
}