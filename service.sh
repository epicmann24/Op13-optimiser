# Important .sh execution line;
#!/system/bin/sh

# Pause execution for Magisk Boot Service;
# Important .sh execution line;
#!/system/bin/sh

# Pause execution for Magisk Boot Service;
sleep 500;

#Credits to EmanuelCN0

### I/O & FS tuning ###

# Reduce urgent gc sleep time.
echo "5" > /dev/sys/fs/by-name/userdata/gc_urgent_sleep_time
echo "5" > /sys/fs/f2fs/dm-43/gc_urgent_sleep_time
echo "5" > /sys/fs/f2fs/sda21/gc_urgent_sleep_time

# Tune F2FS.
echo "20" > /sys/fs/f2fs/dm-43/min_fsync_blocks
echo "20" > /sys/fs/f2fs/sda21/min_fsync_blocks
echo "10000" > /sys/fs/f2fs/dm-43/max_discard_issue_time
echo "10000" > /sys/fs/f2fs/sda21/max_discard_issue_time

# Tune Userdata.
echo "8" > /dev/sys/fs/by-name/userdata/data_io_flag 
echo "8" > /dev/sys/fs/by-name/userdata/node_io_flag
echo "128" > /dev/sys/fs/by-name/userdata/seq_file_ra_mul

# Fully disable I/O stats.
for i in /sys/block/*/queue; do
  echo "0" > $i/iostats;
done;

# Set read_ahead to 128kb.
for i in /sys/block/*/queue; do
  echo "128" > $i/read_ahead_kb;
done;

# Set I/O priority
echo "restrict-to-be" > /dev/blkio/background/blkio.prio.class

# Set default I/O scheduler to mq-deadline
echo "mq-deadline" > /sys/block/sda/queue/scheduler
echo "mq-deadline" > /sys/block/sdb/queue/scheduler
echo "mq-deadline" > /sys/block/sdc/queue/scheduler

### Memory management tuning ###

# Enable MGLRU
echo "0x0003" > /sys/kernel/mm/lru_gen/enabled
echo "5000" > /sys/kernel/mm/lru_gen/min_ttl_ms

# Set vm swapiness to 60.
echo "60" > /proc/sys/vm/swappiness

# Reduce vm stat interval to reduce jitter.
echo "20" > /proc/sys/vm/stat_interval

# Tune dirty data writebacks.
echo "52428800" > /proc/sys/vm/dirty_background_bytes
echo "209715200" > /proc/sys/vm/dirty_bytes

# Disable page cluster.
echo "0" > /proc/sys/vm/page-cluster

# Disable transparent hugepage.
echo "0" > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
echo "never" > /sys/kernel/mm/transparent_hugepage/defrag
echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
echo "never" > /sys/kernel/mm/transparent_hugepage/shmem_enabled
echo "0" > /sys/kernel/mm/transparent_hugepage/use_zero_page

# Set compact_unevictable_allowed to 0 in order to avoid potential stalls that can occur during compactions of unevictable pages, preempt_rt sets it to 0.
echo "0" > /proc/sys/vm/compact_unevictable_allowed

# Set compaction_proactiveness to 0 in order to reduce cpu latency spikes.
echo "0" > /proc/sys/vm/compaction_proactiveness

# Disable oom dump tasks its not desirable for android where we have numerious tasks.
echo "0" > /proc/sys/vm/oom_dump_tasks

### Scheduler tuning ###

# Decrease pelt multiplier to 2 (16ms halflife), to improve power consumption, walt is already quick enough.
echo "2" > /proc/sys/kernel/sched_pelt_multiplier

# Configure uclamp.
echo "1" > /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive
echo "80" > /dev/cpuctl/foreground/cpu.uclamp.max
echo "10" > /dev/cpuctl/background/cpu.uclamp.max
echo "50" > /dev/cpuctl/system-background/cpu.uclamp.max
echo "10" > /dev/cpuctl/dex2oat/cpu.uclamp.max

# Setup cpu.shares to throttle background groups (dex2oat - 2.5% bg ~ 5% sysbg ~ 50% foreground ~ 60%).
echo "1024" > /dev/cpuctl/background/cpu.shares
echo "10240" > /dev/cpuctl/system-background/cpu.shares
echo "512" > /dev/cpuctl/dex2oat/cpu.shares
echo "16384" > /dev/cpuctl/foreground/cpu.shares
echo "20480" > /dev/cpuctl/system/cpu.shares

# We only have /dev/cpuctl/system/cpu.shares system and background groups holding tasks and the groups below are empty.
echo "20480" > /dev/cpuctl/camera-daemon/cpu.shares
echo "20480" > /dev/cpuctl/nnapi-hal/cpu.shares
echo "20480" > /dev/cpuctl/rt/cpu.shares
echo "20480" > /dev/cpuctl/top-app/cpu.shares

# Tune Rate Limits for reduced power usage and improved performance and interactivity.
echo 1000 > /sys/devices/system/cpu/cpufreq/policy0/walt/down_rate_limit_us
echo 1000 > /sys/devices/system/cpu/cpufreq/policy2/walt/down_rate_limit_us
echo 1000 > /sys/devices/system/cpu/cpufreq/policy5/walt/down_rate_limit_us
echo 1000 > /sys/devices/system/cpu/cpufreq/policy7/walt/down_rate_limit_us

echo 500 > /sys/devices/system/cpu/cpufreq/policy0/walt/up_rate_limit_us
echo 500 > /sys/devices/system/cpu/cpufreq/policy2/walt/up_rate_limit_us
echo 500 > /sys/devices/system/cpu/cpufreq/policy5/walt/down_rate_limit_us
echo 500 > /sys/devices/system/cpu/cpufreq/policy7/walt/up_rate_limit_us

# Disable preload, hurts latency and increases powerusage.
echo 0 > /sys/devices/system/cpu/cpufreq/policy0/walt/pl
echo 0 > /sys/devices/system/cpu/cpufreq/policy2/walt/pl
echo 0 > /sys/devices/system/cpu/cpufreq/policy5/walt/pl
echo 0 > /sys/devices/system/cpu/cpufreq/policy7/walt/pl

# Tune input boost
echo "200" > /proc/sys/walt/input_boost/input_boost_ms

# Tune cpusets
echo "0-1" > /dev/cpuset/background/cpus
echo "0-5" > /dev/cpuset/system-background/cpus
echo "0-5" > /dev/cpuset/restricted/cpus
echo "0-5" > /dev/cpuset/foreground/cpus

### IRQ Tuning ###

function write_irq_affinity() {
    # Arguments:
    # $1 = irq name
    # $2 = cpu id
    irq_dir="$(dirname /proc/irq/*/$1)"
    [ -d "$irq_dir" ] && echo $2 > "${irq_dir}/smp_affinity_list"
}
# IRQ Tuning
# hfi -> CPU 1
# msm_drm -> CPU 2
write_irq_affinity hfi 1
write_irq_affinity msm_drm 2

### Disable debugging & logging ##

# Disable sched stats.
echo "0" > /proc/sys/kernel/sched_schedstats

# Disable sync on suspend.
echo "0" > /sys/power/sync_on_suspend

# Disable tracing.
echo "0" > /sys/kernel/tracing/options/trace_printk
echo "0" > /sys/kernel/tracing/tracing_on

# Disable scsi logging.
echo "0" > /proc/sys/dev/scsi/logging_level

# Disable devcoredump.
echo "1" > /sys/class/devcoredump/disabled

### Misc. ###

# Mount debugfs to access some features.
mount -t debugfs none /sys/kernel/debug

# Leverage DynamIQ Shared Unit
echo "0" > /sys/kernel/debug/sched/migration_cost_ns
echo "NO_CACHE_HOT_BUDDY" > /sys/kernel/debug/sched/features

# Disable debug.
echo "N" > /sys/kernel/debug/debug_enabled

# Unmount debugfs.
umount /sys/kernel/debug

# Reduce ufs auto hibernate time to 1ms.
echo "1000" > /sys/bus/platform/devices/1d84000.ufshc/auto_hibern8

# ART heap compaction for cached apps.
settings put global activity_manager__use_compaction true

# Allow up to 64 cached apps in the background.
settings put global activity_manager__max_cached_processes 64

# Disable native stats collection service
stop statsd
 
# Disable console
stop console

# Offload WM shell to another thread
settings put global config_enableShellMainThread true

# Disable CRF
echo "0" > /proc/sys/kernel/sched_child_runs_first

# Wait a little..
# Placeholder..
# And it's done!

#Hi
