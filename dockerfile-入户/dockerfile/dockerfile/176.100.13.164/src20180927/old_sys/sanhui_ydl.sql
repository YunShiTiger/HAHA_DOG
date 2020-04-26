select zh_TASK.ZHIXINGRJH,zh_TASK.LRSJ, zh_ydl.*
from zh_TASK,zh_ydl
where zh_TASK.AUTOORIGINUUID=zh_ydl.UUID
and zh_TASK.LRSJ>:latest
and rownum<1000
order by zh_TASK.LRSJ