require "optparse"
require "parallel"

class DetMatch
    include Comparable
    attr_accessor :iou, :gt_det, :pred_det

    # gt_det, pred_det = bbox = [x, y, w, h]
    def initialize gt_det, pred_det
        @gt_det = gt_det
        @pred_det = pred_det
        @iou = calc_iou(@gt_det, @pred_det)
    end

    def calc_iou gt_det, pred_det
        xA = [gt_det.bb_left, pred_det.bb_left].max
        yA = [gt_det.bb_top, pred_det.bb_top].max
        xB = [gt_det.bb_right, pred_det.bb_right].min
        yB = [gt_det.bb_bottom, pred_det.bb_bottom].min

        inter_area = [0, xB - xA + 1].max * [0, yB - yA + 1].max

        boxAArea = (gt_det.bb_right - gt_det.bb_left + 1) *
                   (gt_det.bb_bottom - gt_det.bb_top + 1)
        boxBArea = (pred_det.bb_right - pred_det.bb_left + 1) *
                   (pred_det.bb_bottom - pred_det.bb_top + 1)

        inter_area / (boxAArea + boxBArea - inter_area).to_f
    end

    def <=> other
        @iou <=> other.iou
    end

    def unmatch
        @pred_det.match = nil
    end
end

class Detection
    attr_accessor :frame, :id, :bb_left, :bb_top, :bb_width, :bb_height, :conf
    attr_accessor :bb_right, :bb_bottom

    # mode = :gt | :pred
    def initialize mode, string
        @match = nil
        if mode == :gt
            @frame, @id,
                @bb_left, @bb_top, @bb_width, @bb_height,
                @conf = string.split(",").map{|s| s.to_i}
        elsif mode == :pred
            @frame = string.split(" - ")[0].split[2].to_i + 1
            arr = string.split(" - ")[1].split
            @bb_left = arr[8].to_i
            @bb_top = arr[11].to_i
            @bb_width = arr[14].to_i
            @bb_height = arr[17].to_i
            @conf = arr[20].to_f
        else
            raise "Invalid mode"
        end
        @type = mode
        @bb_right = @bb_left + @bb_width
        @bb_bottom = @bb_top + @bb_height
    end

    def match_with other
        DetMatch.new(self, other)
    end

    def match
        @match
    end

    def match= match
        @match = match
        if @type == :gt
            match.pred_det.match = match
        end
    end

    def to_s
        "<Detection #{@frame} #{@bb_left} #{@bb_top} #{@bb_width} #{@bb_height}>"
    end
end

def reorganize_dets dets
    output = []
    dets.each do |det|
        index = det.frame
        if output[index].nil?
            output[index] = [det]
        else
            output[index].push det
        end
    end
    output
end

def load_dets_from_file filename, type
    f = File.open(filename)
    if type == :pred
        dets = f.readlines.find_all{|s| s.match "^Entry"}.map{|s| Detection.new(type, s)}
    elsif type == :gt
        dets = f.readlines.map{|s| Detection.new(type, s)}
    end
    f.close

    return reorganize_dets(dets)
end

def load_dets_from_stdin type
    dets = STDIN.readlines.find_all{|s| s.match "^Entry"}.map{|s| Detection.new(type, s)}
    return reorganize_dets(dets)
end

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: acc.rb [options] ground_truth_detections predicted_detections"

    opts.on("-i", "--input-from-stdin", "Take predicted_detections from standard input") do |i|
        options[:input_from_stdin] = i
    end

    opts.on("-a", "--all-matches", "Print all matches and IoUs") do |a|
        options[:print_all_matches] = a
    end
end.parse!

gt_dets_fn = ARGV.shift
unless gt_dets_fn
    puts "No ground_truth_detctions file specified"
    exit 1
end

pred_dets_fn = ARGV.shift
unless pred_dets_fn or options[:input_from_stdin]
    puts "No predicted_detections file specified"
    exit 1
end

# load detections
gt_dets = load_dets_from_file(gt_dets_fn, :gt)
pred_dets = pred_dets_fn ?
    load_dets_from_file(pred_dets_fn, :pred) :
    load_dets_from_stdin(:pred)

# match detections and get accuracy
#motps = Parallel.map((1..(gt_dets.length-1)).to_a, in_processes: 8) do |frame|
motps = (1..(gt_dets.length-1)).to_a.map do |frame|
    frame_gt_dets = gt_dets[frame]
    frame_pred_dets = pred_dets[frame]

    for gt_det in frame_gt_dets
        for pred_det in frame_pred_dets
            if pred_det.match then next end

            old_match = gt_det.match
            match = gt_det.match_with pred_det

            if old_match.nil?
                gt_det.match = match
            elsif match > old_match
                gt_det.match = match
                old_match.unmatch
            end
        end
    end

    if options[:print_all_matches]
               puts frame_gt_dets.map{|d| d.to_s  + (d.match ? "\t#{d.match.pred_det} \t#{d.match.iou}" : "")}
    end

    frame_gt_dets.map{|d| d.match ? d.match.iou : 0}.sum / frame_gt_dets.length.to_f
end

if options[:print_all_matches]
           puts motps.inspect
end
puts motps.sum / motps.length.to_f
